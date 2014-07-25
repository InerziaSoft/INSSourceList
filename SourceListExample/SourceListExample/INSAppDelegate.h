//
//  INSAppDelegate.h
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

#import <Cocoa/Cocoa.h>

#import "INSSourceList.h"

@interface INSAppDelegate : NSObject <NSApplicationDelegate, INSSourceListDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property INSSourceList *sourceList;

@property IBOutlet NSOutlineView *outlineView;

- (IBAction)saveAction:(id)sender;

- (IBAction)addItem:(id)sender;
- (IBAction)addOtherItem:(id)sender;
- (IBAction)removeItem:(id)sender;

- (IBAction)openInerziaSoft:(id)sender;
- (IBAction)openGithubProfile:(id)sender;

@end
