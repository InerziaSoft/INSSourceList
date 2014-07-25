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
 *  @discussion You should always perform any sort on the representedObject key. For example, if you want to sort by a key named "key", you should set up your sortDescriptor to sort on "representedObject.key".
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
@interface INSSourceList : NSObject <NSOutlineViewDelegate, NSTextFieldDelegate>

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
 *  @name Managing Selections
**/

/**
 *  Returns the selected objects.
 *
 *  @discussion This method returns the represented object of each selected node.
**/
- (NSArray*)selectedObjects;

@end
