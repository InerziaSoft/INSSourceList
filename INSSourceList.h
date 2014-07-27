//
//  INSSourceList.h
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

// INSSourceList version 1.1

#import <Cocoa/Cocoa.h>

#pragma mark - INSSourceListDelegate

/**
 *  The INSSourceListDelegate defines the required and optional methods implemented by delegates of the INSSourceList class.
**/
@protocol INSSourceListDelegate <NSObject>

@required

/**
 *  @name Managing Content Structure
**/

/**
 *  Returns the root objects of the OutlineView. At least one object must exists. Each root object must respond to a keypath defined by the -nameKey method.
 *
 *  @warning Returning an empty set is not acceptable, because a SourceList can't be empty. You should have at least one empty header. If this is behavior is incompatible with your application philosophy, you are strongly advised to rethink your use of a SourceList.
 *  @exception NSInternalInconsistencyException thrown when this method returns nil.
 *	@return A NSSet of root objects.
 */
- (NSSet*)roots;

/**
 *  Returns whether an item is a root item or not.
 *
 *  @param item The item for which we are asking if it's root.
 *  @return YES if this item is a root.
 **/
- (BOOL)itemIsRoot:(id)item;

/**
 *  Returns the children of a specified item. The SourceList builds its structure using a recursive function that keeps calling this method until no objects are returned.
 *
 *	@param item The item for which we are asking the children.
 *	@return A NSSet containing the children of item. If item doesn't have any child, an empty NSSet.
 **/
- (NSArray*)childrenForItem:(id)item;

/**
 *  @name Content Displaying
**/

/**
 *  Defines which key should be used to get the name of an object.
 *
 *  @discussion The result of this call is used to represent an object in the SourceList. This key should observe KVO, because it will be binded.
 *  @warning Returning nil here leads to unexpected behaviors.
 *  @return A NSString containing the key.
 **/
- (NSString*)nameKey;

/**
 *  Returns an icon for an item.
 *
 *  @discussion This can be nil.
 *  @param item The item for which we are asking its icon.
 *  @return A NSImage containing the icon for the item, or nil if no icon should be used.
 **/
- (NSImage*)iconForItem:(id)item;

/**
 *  @name Identifying Items
**/

/**
 *  Returns a unique identifier for an object.
 *
 *  @discussion This method is required by the SourceList to uniquely identify a row and it's called frequently.
 *  @warning Returning nil here leads to unexpected behaviors.
 *  @param item The item for which we are asking its unique identifier.
 *  @return A NSString containing the identifier representing the item.
 **/
- (NSString*)uniqueIdentifierForItem:(id)item;

/**
 *  @name Handling Items Events
**/

/**
 *  Returns whether an item should accept selection or not.
 *
 *  @discussion The items for which itemIsRoot answers YES are automatically excluded from the selection.
 *  @param item The item for which we are asking if it can be selected.
 *  @return YES if this item can be selected.
**/
- (BOOL)itemCanBeSelected:(id)item;

@optional

/**
 *  Returns whether an item can be collapsed or not.
 *
 *  @discussion This method is also called to decide whether to show the arrow or the "Show/Hide" text near this item.
 *  @param item The item for which we are asking if it can be collapsed.
 *  @return YES if this item can be collapsed.
 **/
- (BOOL)itemCanBeCollapsed:(id)item;

/**
 *  Informs the SourceList that an item can be edited inline.
 *
 *  @discussion The nameKey method should return a read/write key for this method to work properly, as long as editing will attempt to modify the original object. Roots object are automatically exclued from editing.
 *  @param item The item for which we are asking if it can be edited.
 *  @return YES if the item can be edited.
 **/
- (BOOL)itemCanBeEdited:(id)item;

/**
 *  @name Handling Editing
**/

/**
 *  Called when the SourceList needs to validate a name after editing.
 *
 *  @discussion The delegate must perform any kind of check on the new value here. If the new value is not allowed the SourceList will automatically call the NSTextField's UndoManager to restore the previous value and advise the user with an alert sheet.
 *  @param itemName The value typed by the user. You should always check this value, instead of fetching objects on your own.
 *  @return YES if the new value can be accepted.
 **/
- (BOOL)validateItemNameChange:(NSString*)itemName;

/**
 *  @name Sorting
**/

/**
 *  Returns a list of sortDescriptors that will be used to sort the SourceList tree controller.
 *
 *  @discussion You should always perform any sort on the representedObject key. For example, if you want to sort by a key named "key", you should set up your sortDescriptor to sort on "representedObject.key". If you want to support the automatic row re-ordering of INSSourceList, one of the sortDescriptors returned from this function, must include the indexKey.
 *  @see indexKey
 *  @return A NSArray of NSSortDescriptors that will be passed to the tree controller.
 **/
- (NSArray*)sortDescriptors;

/**
 *  @name Handling OutlineView events
**/

/**
 *  Informs the delegate that the selection in the SourceList has changed.
 *
 *  @discussion This method is optional.
 *  @param notification This notification has the same information as the one sent by the outlineViewSelectionDidChange: method.
**/
- (void)sourceListSelectionDidChange:(NSNotification*)notification;

/**
 *  @name Supporting Drag and Drop
**/

/**
 *  Enables or disables Drag and Drop from inside the SourceList.
 *
 *  @discussion This method is optional. If no implementation is found, dragging is only allowed depending on the supportedDraggedTypes.
 *  @since version 1.1 or later.
 *  @return YES if the SourceList should support drag and drop between its items.
**/
- (BOOL)sourceListShouldSupportInternalDragAndDrop;

/**
 *  Returns an array of supported types that can be dragged onto the SourceList.
 *
 *  @discussion The SourceList automatically enables the ability to drag its items.
 *  @see sourceListShouldSupportInternalDragAndDrop
 *  @since version 1.1 or later.
 *  @return A NSArray of valid NSPasteboard types that should be accepted by the SourceList.
**/
- (NSArray*)supportedDraggedTypes;

/**
 *  Called when an item has been dropped onto another.
 *
 *  @discussion The delegate should update its data accordingly to the drop.
 *  @see sourceListShouldSupportInternalDragAndDrop
 *  @param items An array of items that the user has dropped.
 *  @param item The item on which the items were dropped.
 *  @since version 1.1 or later
 *  @return YES if the drop should be accepted.
**/
- (BOOL)sourceListShouldAcceptDropOfItems:(NSArray*)items onItem:(id)item;

/**
 *  Enables or disables drag and drop reordering in the SourceList.
 *
 *  @discussion If this method returns NO, the user will be able to drag items from the SourceList only onto other items and not in between. This method is ignored when sourceListShouldSupportInternalDragAndDrop returns NO.
 *  @see sourceListShouldSupportInternalDragAndDrop
 *  @since version 1.1 or later
 *  @return YES if the SourceList should allow drag and drop reordering.
 **/
- (BOOL)sourceListShouldAllowItemsReordering;

/**
 *  Called when an item has been dropped onto a particular position.
 *
 *  @discussion The delegate should update its data in order to follow the new sorting. If this method is not implemented, the SourceList will use indexKey to determine the new sorting and then call sourceListShouldAcceptDropOfItems:onItem: to let the delegate updates new possible relationships.
 *  @see sourceListShouldSupportInternalDragAndDrop, sourceListShouldAllowItemsReordering
 *  @param items An array of items that the user has dropped.
 *  @param parent The object on which the items were dropped.
 *  @param index An index representing the position on which the items were dropped, in relation to the parent.
 *  @since version 1.1 or later
 *  @return YES if the drop should be accepted.
**/
- (BOOL)sourceListShouldAcceptDropOfItems:(NSArray*)items onItem:(id)parent asChildrenAtIndex:(NSInteger)index;

/**
 *  Called when something not coming from the SourceList has been dropped onto the SourceList.
 *
 *  @discussion The delegate should its data in order to react to the dropped item. There's no need to call rearrangeObjects on the SourceList after.
 *  @param pasteboard The draggingPasteboard of the drop operation.
 *  @param pasteboardType The NSPasteboard type from which the items have been extracted.
 *  @param item The item on which the items have been dropped.
 *  @param index The index at which the items have been dropped, or -1 if the drop ended right on item.
 *  @see supportedDraggedTypes
 *  @since version 1.1 or later
 *  @return YES if the drop should be accepted.
**/
- (BOOL)sourceListShouldAcceptDropOfDataInPasteboard:(NSPasteboard*)pasteboard ofType:(NSString*)pasteboardType onItem:(id)item asChildrenAtIndex:(NSInteger)index;

/**
 *  Called when the delegate should validate a drop operation onto an object.
 *
 *  @discussion The SourceList automatically invalidates common situations, such as dragging a parent onto its children. If no implementation of this method is found, the SourceList will handle the validation.
 *  @param outlineView The OutlineView of the SourceList. Use this object to redirect drops, if necessary.
 *  @param items The array of items that the user is dragging.
 *  @param parent The parent object on which the user is dragging.
 *  @see sourceListShouldSupportInternalDragAndDrop
 *  @since version 1.1 or later
 *  @return A NSDragOperation that should be used.
**/
- (NSDragOperation)sourceListShouldValidateDropOnOutlineView:(NSOutlineView*)outlineView ofUniqueIdentifiers:(NSArray*)items onItem:(id)parent;

/**
 *  Called when the user wants to start a drag.
 *
 *  @discussion The delegate should decide whether a drag of the selected items is allowed or not. If this method is not implemented, any item of the SourceList can be dragged.
 *  @param items An array of items that the user is trying to drag.
 *  @see sourceListShouldSupportInternalDragAndDrop
 *  @since version 1.1 or later
 *  @return YES if the drag should be allowed.
**/
- (BOOL)sourceListShouldValidateDragOfItems:(NSArray*)items;

/**
 *  Returns the name of the key that should be used to handle row re-ordering in the SourceList.
 *
 *  @discussion This method is called when no implementation of sourceListShouldAcceptDropOfItems:onItem:asChildrenAtIndex is found in the delegate. The SourceList will calculate all the objects indexes according to the user intention and will use this key to store them. As a result, the returning key must be able to contain an NSNumber value.
 *  @warning If this key is not included in one or more NSSortDescriptor(s) returned by sortDescriptors, automatic reordering won't work correctly. If any of the conditions described previously leads to calling this method and the return value is nil, the behavior of the SourceList is undefined.
 *  @since version 1.1 or later
 *  @return A NSString representing the key that should be used to store object indexes.
**/
- (NSString*)indexKey;

/**
 *  Returns the parent object of a specified item.
 *
 *  @discussion This method is required as a workaround to a bug of the NSTreeController that deletes the original NSIndexPath of a dragged object.
 *  @warning If sourceListShouldAllowItemsReordering returns YES, this method is foundamental for the entire operation to work properly. If this method is not implemented, an exception will be thrown and the reordering operation will be dismissed.
 *  @param item The item for which we are asking its parent.
 *  @see sourceListShouldAllowItemsReordering
 *  @since version 1.1 or later
 *  @return A NSString representing the unique identifier of the parent.
**/
- (NSString*)parentUniqueIdentifierForItem:(id)item;

@end

#pragma mark - INSSourceList

/**
 *  INSSourceList automatically handles all the code necessary to build a Source List, just
 *  like the one in the Finder. You can interact and customize this class by registering
 *  one of your objects as a Delegate (following the INSSourceListDelegate protocol).
 *
 *  The INSSourceList can be considered as a sort of Controller for your SourceList.
 *  It takes an OutlineView already configured as a Source List, using the preset available
 *  in Xcode 4 or later and automatically takes care of everything else.
 *
 *  You can choose to use Core Data as a backend for you data, but the SourceList works
 *  with any kind of data.
 *
 *  The delegate is a required part, as long as it's necessary to provide a structure to represent your
 *  data in the OutlineView.
 *
 *  #Advantages of Core Data#
 *  Using the INSSourceList with Core Data simplify the update process, as long as it's handled automatically
 *  by the SourceList itself. Your delegate will be called automatically when it's time to update the OutlineView.
 *  The INSSourceList observes your Managed Object Context to know when something changed, then check if one of the
 *  monitored entities is affected.
 *
**/
@interface INSSourceList : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource, NSTextFieldDelegate>

/**
 *  @name Properties
**/

/**
 *  The OutlineView in which the SourceList should work.
**/
@property (readonly) NSOutlineView *outlineView;

/**
 *  The Core Data entities that the SourceList should monitor for changes.
 *
 *  @discussion This should be a NSSet of NSEntityDescription.
**/
@property (readonly) NSSet *entities;

/**
 *  The Managed Object Context that should be monitored for changes.
 *
 *  @discussion The SourceList does not retain this object.
**/
@property (readonly, weak) NSManagedObjectContext *moc;

/**
 *  The SourceList delegate.
 *
 *  @discussion The SourceList can't work properly without a delegate.
**/
@property (weak) id<INSSourceListDelegate> delegate;

/**
 *  @name Creating and Initializing a SourceList
**/

/**
 *  Initializes, builds the content and returns a new instance of INSSourceList.
 *
 *  @discussion This is the designated convenience initializer when using Core Data.
 *
 *	@param aView          The NSOutlineView used as a source list. This cannot be nil.
 *	@param someEntities   The Core Data entities used by the objects to be displayed. This should be an array of NSEntityDescription objects. This cannot be nil.
 *	@param moc            The NSManagedObjectContext containing the entity. This cannot be nil.
 *	@param aDelegate      An object compliant to the INSSourceListDelegate protocol. This cannot be nil.
 *
 *	@return An initialized instance of the object.
 **/
+ (instancetype)sourceListInOutlineView:(NSOutlineView*)aView coreDataEntities:(NSSet*)someEntities inManagedObjectContext:(NSManagedObjectContext*)moc andDelegate:(id<INSSourceListDelegate>)aDelegate;

/**
 *  Initializes and builds the content of a new instance of INSSourceList.
 *
 *  @discussion This is the designated initializer when using Core Data.
 *
 *	@param aView          The NSOutlineView used as a source list. This cannot be nil.
 *	@param someEntities   The Core Data entities used by the objects to be displayed. This should be an array of NSEntityDescription objects. This cannot be nil.
 *	@param moc            The NSManagedObjectContext containing the entity. This cannot be nil.
 *	@param aDelegate      An object compliant to the INSSourceListDelegate protocol. This cannot be nil.
 *
 *	@return An initialized instance of the object.
**/
- (id)initWithOutlineView:(NSOutlineView*)aView coreDataEntities:(NSSet*)someEntities inManagedObjectContext:(NSManagedObjectContext*)moc andDelegate:(id<INSSourceListDelegate>)aDelegate;

/**
 *  Initializes, buils the content and returns a new instance of INSSourceList.
 *
 *  @discussion This is the designated convenience initializer to use the SourceList without Core Data.
 *
 *  @param aView      The NSOutlineView used as a source list. This cannot be nil.
 *  @param aDelegate  An object compliant to the INSSourceListDelegate protocol. This cannot be nil.
 **/
+ (instancetype)sourceListInOutlineView:(NSOutlineView*)aView andDelegate:(id<INSSourceListDelegate>)aDelegate;

/**
 *  Initializes and buils the content of a new instance of INSSourceList.
 *
 *  @discussion This is the designated initializer to use the SourceList without Core Data.
 *
 *  @param aView      The NSOutlineView used as a source list. This cannot be nil.
 *  @param aDelegate  An object compliant to the INSSourceListDelegate protocol. This cannot be nil.
**/
- (id)initWithOutlineView:(NSOutlineView*)aView andDelegate:(id<INSSourceListDelegate>)aDelegate;

/**
 *  @name Arranging Objects
**/

/**
 *  Forces the SourceList to fetch and rearrange its content. This implies some calls to the delegate.
 *
 *  @discussion This method is automatically called by the designated initializer.
**/
- (void)rearrangeObjects;

/**
 *  Returns the number of children of a specified item.
 *
 *  @since version 1.1 or later
 *  @see rearrangeObjects
 *  @param item The unique identifier of the item for which we are asking its children count.
 *  @return A NSInteger representing the number of children related to item.
**/
- (NSInteger)countOfChildrenForUniqueIdentifier:(NSString*)item;

/**
 *  @name Managing Selections
**/

/**
 *  Returns the selected objects.
 *
 *  @discussion This method returns the represented object of each selected node.
**/
- (NSArray*)selectedObjects;

@end
