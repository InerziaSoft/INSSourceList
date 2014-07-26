//
//  INSAppDelegate.m
//  SourceListExample
//
//  Created by InerziaSoft on 23/07/14.
//  Copyright (c) 2014 InerziaSoft. All rights reserved.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "INSAppDelegate.h"

@implementation INSAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

/*
 Source List Initialization
 
 In this example, we have chose to initialize the SourceList in the applicationDidFinishLaunching, because we have only one window.
 If you plan to use the SourceList in a window different from the main, put this code in the windowDidLoad method of your NSWindowController.
*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // In this example, we are using Core Data. The Source List automatically observe any Managed Object Context change and updates itself accordingly.
    
    _sourceList = [INSSourceList sourceListInOutlineView:self.outlineView coreDataEntities:[NSSet setWithObjects:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.managedObjectContext], [NSEntityDescription entityForName:@"OtherItem" inManagedObjectContext:self.managedObjectContext], nil] inManagedObjectContext:self.managedObjectContext andDelegate:self];
    
    /* If you want to handle Core Data updates on your own, or your application is not based on Core Data, use the other designated initializer.
    
    _sourceList = [INSSourceList sourceListInOutlineView:self.outlineView andDelegate:self];
     
    */
}

#pragma mark -
#pragma mark INSSourceListDelegate

/*
 Root Items
 
 Root items are represented with a gray bold uppercase label and are not selectable.
 They usually contains other items and at least one must exists.
 
 In this example, we have chose to not rely on Core Data for Root items, as long as
 they're static and there would be no point in storing them.
*/
- (NSSet*)roots {
    return [NSSet setWithObjects:[@{self.nameKey: @"ITEMS", @"code": @-30, @"index": @0} mutableCopy], [@{self.nameKey: @"OTHER ITEMS", @"code": @-40, @"index": @1} mutableCopy], nil];
}

/*
 Children
 
 For each item, the SourceList calls this method to get its children.
 This is the only way to have the SourceList reflects your internal structure.
*/
- (NSArray*)childrenForItem:(id)item {
    if (![item isMemberOfClass:[NSManagedObject class]]) {
        switch ([[item valueForKey:@"code"] intValue]) {
            case -30: {
                NSFetchRequest *requ = [[NSFetchRequest alloc] initWithEntityName:@"Item"];
                [requ setPredicate:[NSPredicate predicateWithFormat:@"parent == nil"]];
                NSArray *req = [self.managedObjectContext executeFetchRequest:requ error:nil];
                return req; }
                
            case -40: {
                NSFetchRequest *requ = [[NSFetchRequest alloc] initWithEntityName:@"OtherItem"];
                [requ setPredicate:[NSPredicate predicateWithFormat:@"parent == nil"]];
                NSArray *req = [self.managedObjectContext executeFetchRequest:requ error:nil];
                return req; }
                
            default:
                return [NSArray array];
                break;
        }
    }
    else {
        return [[item valueForKey:@"children"] allObjects];
    }
}

/*
 Item is Root
 
 This method is used to know if an item is root, without indexing all root items again.
*/
- (BOOL)itemIsRoot:(id)item {
    if (![item isMemberOfClass:[NSManagedObject class]]) {
        switch ([[item valueForKey:@"code"] intValue]) {
            case -30:
                
            case -40:
                return YES;
                
            default:
                break;
        }
    }
    return NO;
}

/*
 Item can be Collapsed
 
 An item that contains children can be collapsed by default, regardless of its type (root or child).
 Returning NO here also hide the Show/Hide or the arrow near the item.
*/
- (BOOL)itemCanBeCollapsed:(id)item {
    if (![item isMemberOfClass:[NSManagedObject class]]) {
        switch ([[item valueForKey:@"code"] intValue]) {
            case -30:
                
            case -40:
                return NO;
                
            default:
                break;
        }
    }
    return YES;
}

/*
 Unique Identifier for Item
 
 The SourceList always tries to keep the selection after any operation.
 This method is used to uniquely identify an object and select it again as soon as possible.
*/
- (NSString*)uniqueIdentifierForItem:(id)item {
    if (![item isMemberOfClass:[NSManagedObject class]]) {
        return [[item valueForKey:@"code"] stringValue];
    }
    return [[NSNumber numberWithDouble:[(NSDate*)[item valueForKey:@"added"] timeIntervalSince1970]] stringValue];
}

/*
 Item can be Selected
 
 Any item can be selected, except root items. 
 We don't need any check here, because the only items that we don't want to be selectable are just the root items.
*/
- (BOOL)itemCanBeSelected:(id)item {
    return YES;
}

/*
 Name Key
 
 This is the key that the SourceList should display.
 If you want to implement editing, you should provide a read/write key.
*/
- (NSString*)nameKey {
    return @"name";
}

/*
 Icon for Item
 
 Any object can have an icon. Returning nil means that no icon will be displayed.
*/
- (NSImage*)iconForItem:(id)item {
    return nil;
}

/*
 SourceList Selection did Change
 
 Use this method to implement updates when the selection changes.
*/
- (void)sourceListSelectionDidChange:(NSNotification*)notification {
    
}

/*
 Item can be Edited
 
 Any item can be edited, except root items.
 We don't need any check here, because the only items that we don't want to be edited are just the root items.
*/
- (BOOL)itemCanBeEdited:(id)item {
    return YES;
}

/*
 Validate Item Name Change
 
 We are allowing any name, even duplicate ones.
 If you need to do some validation before allowing the user to complete the editing, use this method.

- (BOOL)validateItemNameChange:(NSString*)itemName {
    return YES;
}
*/


/*
 Sort Descriptors
 
 If you want to sort the SourceList, return one or more valid Sort Descriptors.
 To access to the object of each row, use the representedObject key.
 
 If you want to take advantage of the automatic Drag and Drop sorting of INSSourceList,
 one of the NSSortDescriptor(s) below must contain the index key.
 
 Please note that sorting also modify the order of the root items.
*/
- (NSArray*)sortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"representedObject.index" ascending:YES]];
}

#pragma mark -
#pragma mark Handling Drag and Drop

- (BOOL)sourceListShouldSupportInternalDragAndDrop {
    return YES;
}

- (BOOL)sourceListShouldAllowItemsReordering {
    return YES;
}

- (BOOL)sourceListShouldAcceptDropOfItems:(NSArray *)items onItem:(id)item {
    if ([item isMemberOfClass:[NSManagedObject class]]) {
        for (NSManagedObject *obj in items) {
            [obj setValue:item forKey:@"parent"];
            return YES;
        }
    }
    else {
        for (NSManagedObject *obj in items) {
            if (([obj.entity.name isEqualToString:@"Item"] && [[item valueForKey:@"code"] intValue] == -30) || ([obj.entity.name isEqualToString:@"OtherItem"] && [[item valueForKey:@"code"] intValue] == -40)) {
                [obj setValue:nil forKey:@"parent"];
                return YES;
            }
        }
    }
    
    return NO;
}

- (NSString*)indexKey {
    return @"index";
}

- (NSString*)parentUniqueIdentifierForItem:(id)item {
    if ([item isMemberOfClass:[NSManagedObject class]]) {
        if ([item valueForKeyPath:@"parent"] != nil) {
            return [self uniqueIdentifierForItem:[item valueForKeyPath:@"parent"]];
        }
        else {
            return ([((NSManagedObject*)item).entity.name isEqualToString:@"Item"])?[@-30 stringValue]:[@-40 stringValue];
        }
    }
    
    return nil;
}

#pragma mark -
#pragma mark Core Data

- (IBAction)addItem:(id)sender {
    NSManagedObject *obj = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
    long index = (long)[self.sourceList countOfChildrenForUniqueIdentifier:[@-30 stringValue]];
    [obj setValue:[NSString stringWithFormat:@"New Object %li", index+1] forKeyPath:@"name"];
    [obj setValue:[NSNumber numberWithLong:index] forKeyPath:@"index"];
    [obj setValue:[NSDate date] forKeyPath:@"added"];
}

- (IBAction)addOtherItem:(id)sender {
    NSManagedObject *obj = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"OtherItem" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext];
    long index = (long)[self.sourceList countOfChildrenForUniqueIdentifier:[@-40 stringValue]];
    [obj setValue:[NSString stringWithFormat:@"New Object %li", index+1] forKeyPath:@"name"];
    [obj setValue:[NSNumber numberWithLong:index] forKeyPath:@"index"];
    [obj setValue:[NSDate date] forKeyPath:@"added"];
}

- (IBAction)removeItem:(id)sender {
    for (NSManagedObject *obj in [self.sourceList selectedObjects]) {
        [self.managedObjectContext deleteObject:obj];
    }
}

- (IBAction)openInerziaSoft:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.inerziasoft.eu/"]];
}

- (IBAction)openGithubProfile:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/InerziaSoft"]];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "eu.inerziasoft.SourceListExample" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"eu.inerziasoft.SourceListExample"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SourceListExample" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"SourceListExample.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
