//
//  INSSourceList.m
//
//  Created by InerziaSoft on 20/07/14.
//  Copyright (c) 2014 InerziaSoft. All rights reserved.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "INSSourceList.h"

@interface INSSourceListTransformToUppercase : NSValueTransformer

@end

#pragma mark -
#pragma mark ValueTransformer

@implementation INSSourceListTransformToUppercase

+ (Class)transformedValueClass {return [NSString class];}
+ (BOOL)allowsReverseTransformation {return YES;}
- (id)transformedValue:(id)value {
	return [value uppercaseString];
}

@end

#pragma mark -
#pragma mark Source List

@interface INSSourceList ()

@property NSTreeController *treeController;
@property NSMutableArray *content;

@property NSString *lastSelectedItem;

@end

@implementation INSSourceList

#pragma mark -
#pragma mark Init with Core Data

+ (instancetype)sourceListInOutlineView:(NSOutlineView*)aView coreDataEntities:(NSSet*)someEntities inManagedObjectContext:(NSManagedObjectContext*)moc andDelegate:(id<INSSourceListDelegate>)aDelegate {
    return [[self alloc] initWithOutlineView:aView coreDataEntities:someEntities inManagedObjectContext:moc andDelegate:aDelegate];
}

- (id)initWithOutlineView:(NSOutlineView*)aView coreDataEntities:(NSSet*)someEntities inManagedObjectContext:(NSManagedObjectContext*)moc andDelegate:(id<INSSourceListDelegate>)aDelegate {
    if (self = [self initWithOutlineView:aView andDelegate:aDelegate]) {
        if (someEntities != nil && moc != nil) {
            _entities = someEntities;
            _moc = moc;
        }
        else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"-[%@ %@]: no entities or managed object context to monitor. If you don't want to use Core Data with the Source List, use initWithOutlineView:andDelegate: instead.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:_moc];
    }
    return self;
}

#pragma mark -
#pragma mark Init without Core Data

+ (id)sourceListInOutlineView:(NSOutlineView*)aView andDelegate:(id<INSSourceListDelegate>)aDelegate {
    return [[self alloc] initWithOutlineView:aView andDelegate:aDelegate];
}

- (id)initWithOutlineView:(NSOutlineView*)aView andDelegate:(id<INSSourceListDelegate>)aDelegate {
    if (self = [super init]) {
        if (aDelegate != nil) {
            _delegate = aDelegate;
            
            _outlineView = aView;
            
            _treeController = [[NSTreeController alloc] init];
            [_treeController setChildrenKeyPath:@"childNodes"];
            [_treeController setLeafKeyPath:@"isLeaf"];
            [_treeController bind:NSContentArrayBinding toObject:self withKeyPath:@"content" options:nil];
            
            [_outlineView bind:NSContentBinding toObject:self.treeController withKeyPath:@"arrangedObjects" options:nil];
            [_outlineView bind:NSSelectionIndexPathsBinding toObject:self.treeController withKeyPath:@"selectionIndexPaths" options:nil];
            [_outlineView bind:NSSortDescriptorsBinding toObject:self.treeController withKeyPath:@"sortDescriptors" options:nil];
            [_outlineView setDelegate:self];
            
            [_outlineView setFloatsGroupRows:NO];
            
            [self rearrangeObjects];
        }
        else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"-[%@ %@]: unable to work with a nil delegate.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
        }
    }
    return self;
}

#pragma mark - NSManagedObjectContextDidChange

- (void)contextDidChange:(NSNotification *)notif {
    NSSet *added = [notif userInfo][NSInsertedObjectsKey];
    NSSet *changed = [notif userInfo][NSUpdatedObjectsKey];
    NSSet *deleted = [notif userInfo][NSDeletedObjectsKey];
    
    NSMutableSet *total = [NSMutableSet setWithSet:added];
    [total addObjectsFromArray:[changed allObjects]];
    [total addObjectsFromArray:[deleted allObjects]];
    
    if ([self entityIsAffectedForObjects:total]) {
        [self rearrangeObjects];
    }
}

- (BOOL)entityIsAffectedForObjects:(NSSet*)objects {
    for (NSManagedObject *obj in objects) {
        for (NSEntityDescription *entity in self.entities) {
            if ([obj.entity.name isEqualToString:entity.name]) {
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark - Content

- (void)rearrangeObjects {
    if (self.content.count > 0 && self.treeController.selectedNodes.count > 0) {
        self.lastSelectedItem = [self.delegate uniqueIdentifierForItem:[[[self.treeController.selectedNodes objectAtIndex:0] representedObject] representedObject]];
    }
    
    [self.treeController setSortDescriptors:nil];
    
    [self willChangeValueForKey:@"content"];
    self.content = [NSMutableArray array];
    [self didChangeValueForKey:@"content"];
    
    if ([self.delegate respondsToSelector:@selector(roots)]) {
        NSSet *roots = [self.delegate roots];
        
        if (roots != nil && roots.count > 0) {
            int i = 0;
            for (id obj in roots) {
                NSTreeNode *node = [NSTreeNode treeNodeWithRepresentedObject:obj];
                NSIndexPath *originalIndex = [NSIndexPath indexPathWithIndex:i];
                [self.treeController insertObject:node atArrangedObjectIndexPath:originalIndex];
                
                [self recursiveChildrenWithObject:obj withParentIndex:originalIndex];
                
                i++;
            }
            
            if ([self.delegate respondsToSelector:@selector(sortDescriptors)]) {
                [_treeController setSortDescriptors:[self.delegate sortDescriptors]];
            }
            [self.treeController rearrangeObjects];
            
            if (self.lastSelectedItem != nil) {
                NSMutableArray *content = [self.treeController content];
                [content sortUsingDescriptors:[self.delegate sortDescriptors]];
                if (content.count > 0) {
                    i = 0;
                    NSIndexPath *toSelect = nil;
                    for (NSTreeNode *node in content) {
                        toSelect = [self recursiveFindItemWithObject:node andParentIndex:[NSIndexPath indexPathWithIndex:i]];
                        
                        if (toSelect.length > 1) {
                            break;
                        }
                        
                        i++;
                    }
                    
                    if (toSelect != nil && toSelect.length > 1) {
                        [self.treeController setSelectionIndexPath:toSelect];
                    }
                    else {
                        [self selectFirstApplicableItem];
                    }
                }
            }
            else {
                [self selectFirstApplicableItem];
            }
            self.lastSelectedItem = nil;
        }
        else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"-[%@ %@]: Source List must have at least one root item.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
        }
    }
    else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"-[%@ %@]: Source List delegate does not respond to selector -(NSSet*)roots!", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
    }
}

- (void)selectFirstApplicableItem {
    NSMutableArray *content = [self.treeController content];
    [content sortUsingDescriptors:[self.delegate sortDescriptors]];
    
    if (content.count > 0) {
        NSIndexPath *toSelect = nil;
        for (int i = 0; i < content.count; i++) {
            if ([[content[i] childNodes] count] > 0) {
                toSelect = [[NSIndexPath indexPathWithIndex:i] indexPathByAddingIndex:0];
            }
        }
        
        [self.treeController setSelectionIndexPath:toSelect];
    }
}

- (NSIndexPath*)recursiveFindItemWithObject:(NSTreeNode*)node andParentIndex:(NSIndexPath*)originalIndex {
    NSArray *children = [[node childNodes] sortedArrayUsingDescriptors:[self.delegate sortDescriptors]];
    
    if (children.count > 0) {
        int x = 0;
        for (NSTreeNode *node in children) {
            if ([[self.delegate uniqueIdentifierForItem:[node representedObject]] isEqualToString:self.lastSelectedItem]) {
                return [originalIndex indexPathByAddingIndex:x];
            }
            else {
                NSIndexPath *path = nil;
                path = [self recursiveFindItemWithObject:node andParentIndex:[originalIndex indexPathByAddingIndex:x]];
                if (path.length > originalIndex.length+1) {
                    return path;
                }
            }
            x++;
        }
    }
    return originalIndex;
}

- (void)recursiveChildrenWithObject:(id)obj withParentIndex:(NSIndexPath*)originalIndex {
    NSArray *children = [self.delegate childrenForItem:obj];
    
    if (children.count > 0) {
        int x = 0;
        for (id child in children) {
            NSTreeNode *childNode = [NSTreeNode treeNodeWithRepresentedObject:child];
            NSIndexPath *indexPath = [originalIndex indexPathByAddingIndex:x];
            [self.treeController insertObject:childNode atArrangedObjectIndexPath:indexPath];
            
            [self recursiveChildrenWithObject:child withParentIndex:indexPath];
            
            x++;
        }
    }
}

#pragma mark -
#pragma mark Selection

- (NSArray*)selectedObjects {
    NSMutableArray *objs = [NSMutableArray array];
    for (NSTreeNode *node in self.treeController.selectedNodes) {
        [objs addObject:[[node representedObject] representedObject]];
    }
    return objs;
}

#pragma mark - NSOutlineView


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([self.delegate respondsToSelector:@selector(itemIsRoot:)]) {
        if (![self.delegate itemIsRoot:[[item representedObject] representedObject]]) {
            return [self.delegate itemCanBeSelected:[[item representedObject] representedObject]];
        }
    }
    else {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"-[%@ %@]: SourceList delegate does not respond to itemIsRoot. Selection will be prevented.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
    }
    return NO;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    if ([self.delegate respondsToSelector:@selector(itemIsRoot:)]) {
        return [self.delegate itemIsRoot:[[item representedObject] representedObject]];
    }
    else {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"-[%@ %@]: SourceList delegate does not respond to itemIsRoot.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(sourceListSelectionDidChange:)]) {
        [self.delegate sourceListSelectionDidChange:notification];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    if ([self.delegate respondsToSelector:@selector(itemCanBeCollapsed:)]) {
        return [self.delegate itemCanBeCollapsed:[[item representedObject] representedObject]];
    }
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
	return [self outlineView:outlineView shouldCollapseItem:item];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *view = nil;
    NSDictionary *opt = nil;
    
    if ([self.delegate respondsToSelector:@selector(itemIsRoot:)]) {
        if ([self.delegate itemIsRoot:[[item representedObject] representedObject]]) {
            view = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
            opt = @{NSValueTransformerNameBindingOption: @"INSSourceListTransformToUppercase"};
        }
        else {
            view = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
            [view.imageView setImage:[self.delegate iconForItem:[[item representedObject] representedObject]]];
            
            if ([self.delegate respondsToSelector:@selector(itemCanBeEdited:)]) {
                if ([self.delegate itemCanBeEdited:[[item representedObject] representedObject]]) {
                    [view.textField setEditable:YES];
                    [view.textField setDelegate:self];
                }
            }
        }
        
        [view.textField bind:NSValueBinding toObject:[[item representedObject] representedObject] withKeyPath:self.delegate.nameKey options:opt];
    }
    else {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"-[%@ %@]: SourceList delegate does not respond to itemIsRoot.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
    }
    
    return view;
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    if ([self.delegate respondsToSelector:@selector(validateItemNameChange:)]) {
        NSString *present = [[fieldEditor string] copy];
        if ([self.delegate validateItemNameChange:[fieldEditor string]]) {
            NSAlert *theAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The name '%1$@' is already in use.", @"INSSourceList - Validation failed message text"), present] defaultButton:NSLocalizedString(@"Cancel", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Please, provide another name and try again.", @"INSSourceList - Validation failed informative text")];
            [theAlert beginSheetModalForWindow:self.outlineView.window completionHandler:nil];
            [[fieldEditor undoManager] undo];
        }
    }
	return YES;
}


@end
