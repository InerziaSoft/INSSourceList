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

#define INSSourceListInternalDragPboardType @"outlineInternalDragPboardType"

#pragma mark -
#pragma mark ValueTransformer

@interface INSSourceListTransformToUppercase : NSValueTransformer

@end

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
#pragma mark Description

- (NSString*)description {
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"\n"];
    for (NSTreeNode *node in [self.content sortedArrayUsingDescriptors:[self.delegate sortDescriptors]]) {
        [result appendString:[NSString stringWithFormat:@"#(%@) ", [[node representedObject] valueForKeyPath:[self.delegate indexKey]]]];
        [result appendString:[[node representedObject] valueForKeyPath:[self.delegate nameKey]]];
        [result appendString:@"\n"];
        
        if (node.childNodes.count > 0) {
            [result appendString:[self recursiveStringWithNode:node withLevel:1]];
        }
    }
    
    return result;
}

- (NSString*)recursiveStringWithNode:(NSTreeNode*)node withLevel:(int)level {
    NSMutableString *result = [NSMutableString string];
    for (NSTreeNode *child in [node.childNodes sortedArrayUsingDescriptors:[self.delegate sortDescriptors]]) {
        for (int i = 0; i < level; i++) {
            [result appendString:@"\t"];
        }
        
        [result appendString:[NSString stringWithFormat:@"#(%@) ", [[child representedObject] valueForKeyPath:[self.delegate indexKey]]]];
        [result appendString:[[child representedObject] valueForKeyPath:[self.delegate nameKey]]];
        [result appendString:@"\n"];
        
        if (child.childNodes.count > 0) {
            [result appendString:[self recursiveStringWithNode:child withLevel:level+1]];
        }
    }
    
    return result;
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
            [_outlineView setDataSource:self];
            
            NSMutableArray *draggedTypes = [NSMutableArray array];
            
            if ([self.delegate respondsToSelector:@selector(sourceListShouldSupportInternalDragAndDrop)] && [self.delegate sourceListShouldSupportInternalDragAndDrop]) {
                [draggedTypes addObject:INSSourceListInternalDragPboardType];
            }
            
            if ([self.delegate respondsToSelector:@selector(supportedDraggedTypes)]) {
                [draggedTypes addObjectsFromArray:[self.delegate supportedDraggedTypes]];
            }
        
            [_outlineView registerForDraggedTypes:draggedTypes];
            
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
                NSIndexPath *originalIndex = [NSIndexPath indexPathWithIndex:i];
                NSTreeNode *node = [NSTreeNode treeNodeWithRepresentedObject:obj];
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
                        toSelect = [self recursiveFindItemWithObject:node andParentIndex:[NSIndexPath indexPathWithIndex:i] withUniqueIdentifier:self.lastSelectedItem];
                        
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
    
    if ([self.delegate respondsToSelector:@selector(sortDescriptors)]) {
        [content sortUsingDescriptors:[self.delegate sortDescriptors]];
    }
    
    if (content.count > 0) {
        NSIndexPath *toSelect = nil;
        for (int i = 0; i < content.count; i++) {
            if ([[content[i] childNodes] count] > 0) {
                toSelect = [[NSIndexPath indexPathWithIndex:i] indexPathByAddingIndex:0];
                break;
            }
        }
        
        [self.treeController setSelectionIndexPath:toSelect];
    }
}

- (void)recursiveChildrenWithObject:(id)obj withParentIndex:(NSIndexPath*)originalIndex {
    if ([self.delegate respondsToSelector:@selector(childrenForItem:)]) {
        NSArray *children = [self.delegate childrenForItem:obj];
        
        if (children != nil && children.count > 0) {
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
    else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"-[%@ %@]: Source List delegate does not implement childrenForItem method!", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
    }
}

- (void)updateNodesIndexes {
    int i = 0;
    for (NSTreeNode *node in [self.content sortedArrayUsingDescriptors:[self.delegate sortDescriptors]]) {
        if ([node respondsToSelector:@selector(representedObject)]) {
            [[node representedObject] setValue:[NSNumber numberWithInt:i] forKeyPath:[self.delegate indexKey]];
            
            if (node.childNodes.count > 0) {
                [self recursiveUpdateNodesIndexesWithNode:node];
            }
            
            i++;
        }
    }
}

- (void)recursiveUpdateNodesIndexesWithNode:(NSTreeNode*)node {
    int i = 0;
    
    for (NSTreeNode *child in [[node childNodes] sortedArrayUsingDescriptors:[self.delegate sortDescriptors]]) {
        [[child representedObject] setValue:[NSNumber numberWithInt:i] forKeyPath:[self.delegate indexKey]];
        
        if (child.childNodes.count > 0) {
            [self recursiveUpdateNodesIndexesWithNode:child];
        }
        
        i++;
    }
}

- (NSIndexPath*)recursiveFindItemWithObject:(NSTreeNode*)node andParentIndex:(NSIndexPath*)originalIndex withUniqueIdentifier:(NSString*)uniqueIdentifier {
    NSArray *children = [[node childNodes] sortedArrayUsingDescriptors:[self.delegate sortDescriptors]];
    
    if (children.count > 0) {
        int x = 0;
        for (NSTreeNode *node in children) {
            if ([[self.delegate uniqueIdentifierForItem:[node representedObject]] isEqualToString:uniqueIdentifier]) {
                return [originalIndex indexPathByAddingIndex:x];
            }
            else {
                NSIndexPath *path = [self recursiveFindItemWithObject:node andParentIndex:[originalIndex indexPathByAddingIndex:x] withUniqueIdentifier:uniqueIdentifier];
                if (path.length > originalIndex.length+1) {
                    return path;
                }
            }
            x++;
        }
    }
    return originalIndex;
}

- (NSTreeNode*)nodeWithUniqueIdentifier:(NSString*)uniqueIdentifier {
    for (NSTreeNode *node in self.content) {
        if ([[self.delegate uniqueIdentifierForItem:[node representedObject]] isEqualToString:uniqueIdentifier]) {
            return node;
        }
        else {
            NSTreeNode *item = [self recursiveNode:node andUniqueIdentifier:uniqueIdentifier];
            
            if (item != nil) {
                return item;
            }
        }
    }
    return nil;
}

- (NSTreeNode*)recursiveNode:(NSTreeNode*)node andUniqueIdentifier:(NSString*)uniqueIdentifier {
    NSArray *children = [node childNodes];
    
    if (children.count > 0) {
        for (NSTreeNode *node in children) {
            if ([[self.delegate uniqueIdentifierForItem:[node representedObject]] isEqualToString:uniqueIdentifier]) {
                return node;
            }
            else {
                NSTreeNode *item = [self recursiveNode:node andUniqueIdentifier:uniqueIdentifier];
                
                if (item != nil) {
                    return item;
                }
            }
        }
    }
    return nil;
}

- (id)itemWithUniqueIdentifier:(NSString*)uniqueIdentifier {
    return [[self nodeWithUniqueIdentifier:uniqueIdentifier] representedObject];
}

- (NSInteger)countOfChildrenForUniqueIdentifier:(NSString*)item {
    return [[[self nodeWithUniqueIdentifier:item] childNodes] count];
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

#pragma mark - NSOutlineViewDelegate


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([self.delegate respondsToSelector:@selector(itemIsRoot:)]) {
        if (![self.delegate itemIsRoot:[[item representedObject] representedObject]]) {
            if ([self.delegate respondsToSelector:@selector(itemCanBeSelected:)]) {
                return [self.delegate itemCanBeSelected:[[item representedObject] representedObject]];
            }
            else {
                @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"-[%@ %@]: SourceList delegate does not respond to itemCanBeSelected. Selection will be prevented.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
            }
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
            
            if ([self.delegate respondsToSelector:@selector(iconForItem:)]) {
                [view.imageView setImage:[self.delegate iconForItem:[[item representedObject] representedObject]]];
            }
            else {
                [view.imageView setImage:nil];
            }
            
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

#pragma mark - NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    if ([[info draggingPasteboard] dataForType:INSSourceListInternalDragPboardType] != nil) {
        NSData *draggedItemsData = [[info draggingPasteboard] dataForType:INSSourceListInternalDragPboardType];
        NSArray *items = [NSKeyedUnarchiver unarchiveObjectWithData:draggedItemsData];
        
        NSMutableArray *realObjs = [NSMutableArray array];
        for (NSString *identifier in items) {
            id item = [self itemWithUniqueIdentifier:identifier];
            if (item != nil) {
                [realObjs addObject:item];
            }
        }
        
        if (index == -1) {
            id rep = [item representedObject];
            if ([rep isMemberOfClass:[NSTreeNode class]]) {
                rep = [rep representedObject];
            }
            
            if ([self.delegate sourceListShouldAcceptDropOfItems:realObjs onItem:rep]) {
                [self rearrangeObjects];
                
                [self updateNodesIndexes];
                
                return YES;
            }
        }
        else {
            if ([self.delegate respondsToSelector:@selector(sourceListShouldAcceptDropOfItems:onItem:asChildrenAtIndex:)]) {
                return [self.delegate sourceListShouldAcceptDropOfItems:realObjs onItem:[[item representedObject] representedObject] asChildrenAtIndex:index];
            }
            else {
                NSTreeNode *updatedItem = item;
                NSString *parentIdentifier = [self.delegate parentUniqueIdentifierForItem:realObjs[0]];
                
                if (![parentIdentifier isEqualToString:[self.delegate uniqueIdentifierForItem:[[item representedObject] representedObject]]]) {
                    if (![self outlineView:outlineView acceptDrop:info item:item childIndex:-1]) {
                        return NO;
                    }
                    
                    updatedItem = [self nodeWithUniqueIdentifier:[self.delegate uniqueIdentifierForItem:[[item representedObject] representedObject]]];
                }
                
                NSInteger oldRow = [[realObjs[0] valueForKey:[self.delegate indexKey]] integerValue];
                NSInteger updatedRow = index;
                if (oldRow < index) {
                    updatedRow--;
                }
                
                [realObjs[0] setValue:@(updatedRow) forKeyPath:[self.delegate indexKey]];
                
                NSArray *realNodes = [updatedItem childNodes];
                
                if (realNodes.count > 0 && [[realNodes[0] representedObject] isMemberOfClass:[NSTreeNode class]]) {
                    NSMutableArray *temp = [NSMutableArray array];
                    for (id fakeTreeNode in realNodes) {
                        [temp addObject:[fakeTreeNode representedObject]];
                    }
                    realNodes = temp;
                }
                
                NSArray *orderedChildren = [realNodes sortedArrayUsingDescriptors:[self.delegate sortDescriptors]];
                
                if (oldRow < index) {
                    for (NSInteger i = oldRow; i < index; i++) {
                        if (![[self.delegate uniqueIdentifierForItem:[orderedChildren[i] representedObject]] isEqualToString:items[0]]) {
                            [[orderedChildren[i] representedObject] setValue:@(([[[orderedChildren[i] representedObject] valueForKey:[self.delegate indexKey]] intValue] != 0)?[[[orderedChildren[i] representedObject] valueForKey:[self.delegate indexKey]] intValue]-1:0) forKey:[self.delegate indexKey]];
                        }
                    }
                }
                else {
                    for (NSInteger i = oldRow; i >= index; i--) {
                        if (![[self.delegate uniqueIdentifierForItem:[orderedChildren[i] representedObject]] isEqualToString:items[0]]) {
                            [[orderedChildren[i] representedObject] setValue:@([[[orderedChildren[i] representedObject] valueForKey:[self.delegate indexKey]] intValue]+1) forKey:[self.delegate indexKey]];
                        }
                    }
                }
                
                [self rearrangeObjects];
                
                return YES;
            }
        }
    }
    else {
        for (NSString *dropType in self.outlineView.registeredDraggedTypes) {
            if ([[[info draggingPasteboard] types] containsObject:dropType]) {
                if ([self.delegate respondsToSelector:@selector(sourceListShouldAcceptDropOfDataInPasteboard:ofType:onItem:asChildrenAtIndex:)]) {
                    BOOL accepted = [self.delegate sourceListShouldAcceptDropOfDataInPasteboard:[info draggingPasteboard] ofType:dropType onItem:[[item representedObject] representedObject] asChildrenAtIndex:index];
                    
                    if (accepted) {
                        [self rearrangeObjects];
                        return YES;
                    }
                }
                else {
                    return NO;
                }
            }
        }
    }
    
    return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if (index != -1 && (![self.delegate respondsToSelector:@selector(sourceListShouldAllowItemsReordering)] || ![self.delegate sourceListShouldAllowItemsReordering])) {
        [outlineView setDropItem:item dropChildIndex:-1];
    }
    
    if ([info draggingSource] == self.outlineView) {
        if ([[info draggingPasteboard] dataForType:INSSourceListInternalDragPboardType] != nil) {
            NSData *draggedItemsData = [[info draggingPasteboard] dataForType:INSSourceListInternalDragPboardType];
            NSArray *items = [NSKeyedUnarchiver unarchiveObjectWithData:draggedItemsData];
            
            for (NSString *identifier in items) {
                NSTreeNode *parent = item;
                
                while ([[parent representedObject] respondsToSelector:@selector(representedObject)]) {
                    id reprObj = [[parent representedObject] representedObject];
                    
                    if ([identifier isEqualToString:[self.delegate uniqueIdentifierForItem:reprObj]]) {
                        return NSDragOperationNone;
                    }
                    
                    parent = [parent parentNode];
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(sourceListShouldValidateDropOnOutlineView:ofUniqueIdentifiers:onItem:)]) {
                return [self.delegate sourceListShouldValidateDropOnOutlineView:outlineView ofUniqueIdentifiers:items onItem:[[item representedObject] representedObject]];
            }
        }
    }
    else {
        if ([self.delegate respondsToSelector:@selector(sourceListShouldValidateDropOfDataInPasteboard:onItem:asChildrenAtIndex:)]) {
            return [self.delegate sourceListShouldValidateDropOfDataInPasteboard:[info draggingPasteboard] onItem:[[item representedObject] representedObject] asChildrenAtIndex:index];
        }
        return NSDragOperationGeneric;
    }
    
    return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    if ([self.delegate respondsToSelector:@selector(sourceListShouldSupportInternalDragAndDrop)] && [self.delegate sourceListShouldSupportInternalDragAndDrop]) {
        NSMutableArray *realItemsIdentifiers = [NSMutableArray array];
        NSMutableArray *realItems = [NSMutableArray array];
        for (NSTreeNode *node in items) {
            [realItemsIdentifiers addObject:[self.delegate uniqueIdentifierForItem:[[node representedObject] representedObject]]];
            [realItems addObject:[[node representedObject] representedObject]];
        }
        
        if ([self.delegate respondsToSelector:@selector(sourceListShouldValidateDragOfItems:)] && ![self.delegate sourceListShouldValidateDragOfItems:realItems]) {
            return NO;
        }
        
        NSData *realData = [NSKeyedArchiver archivedDataWithRootObject:realItemsIdentifiers];
        [pasteboard declareTypes:[NSArray arrayWithObject:INSSourceListInternalDragPboardType] owner:self];
        [pasteboard setData:realData forType:INSSourceListInternalDragPboardType];
        return YES;
    }
    return NO;
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
