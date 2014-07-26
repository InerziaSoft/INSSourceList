INSSourceList
=============
INSSourceList aims to become a complete and fully featured class to manage a Source List on OS X 10.7 or later using Core Data.

Apple has introduced the concept of Source List with OS X 10.3, in the Finder, but never released a complete tutorial on how to reproduce it in any Cocoa application.

With OS X 10.7 and Xcode 4, a new template named "Source List" has been introduced, but never explained. INSSourceList takes this preset object and expands its possibilities, by adding complete Core Data support.

The main target of this class is to provide a plug & play solution to include a Source List in your Core Data application.

Getting Started
=============
INSSourceList currently supports a standard Cocoa environment, with and without Core Data.

When initialised with Core Data, the INSSourceList automatically handles updates, by observing the Managed Object Context for changes.

There's no way to convert an INSSourceList initialised with Core Data to a non-Core Data based one.

INSSourceList is composed of two files: INSSourceList.h and its implementation .m. Start by adding these files to your Xcode project. When done, follow the appropriate guide, depending on your use of Core Data.

## With Core Data

1. Choose one of your objects (or create a new one) and import **INSSourceList.h**.
2. Define that object to be compliant to the **INSSourceListDelegate** protocol.
3. Still in that object, add a property of class **INSSourceList**. This will be used to retain the SourceList during runtime. If you plan to include the SourceList in a window, put this property in the Window Controller.
4. Switch to the XIB where you want to put your SourceList. Search for the preset object called "**Source List**" and drag it into where you want.
5. Now, go back to the designated Delegate object and add an IBOutlet to the SourceList you just created (it's a standard *NSOutlineView*).
6. Switch to the implementation and choose an appropriate method where to put the INSSourceList initialization (in a Window Controller, the right method would be windowDidLoad). The correct way to initialize INSSourceList to work with Core Data is by using its designated initializer: `+ (instancetype)sourceListInOutlineView:(NSOutlineView*)aView coreDataEntity:(NSEntityDescription*)aEntity inManagedObjectContext:(NSManagedObjectContext*)moc andDelegate:(id<INSSourceListDelegate>)aDelegate`. You should provide some information to the Source List, such as the OutlineView in which it should work, the Core Data entity that contains the objects you'd like to display into the Source List, the Managed Object Context and an object as its delegate (pass the one that you chose before - take a look at the included example project for further information).
7. Implement all the required methods of the INSSourceListDelegate protocol and you're done.

## Without Core Data

1. Choose one of your objects (or create a new one) and import **INSSourceList.h**.
2. Define that object to be compliant to the **INSSourceListDelegate** protocol.
3. Still in that object, add a property of class **INSSourceList**. This will be used to retain the SourceList during runtime. If you plan to include the SourceList in a window, put this property in the Window Controller.
4. Switch to the XIB where you want to put your SourceList. Search for the preset object called "**Source List**" and drag it into where you want.
5. Now, go back to the designated Delegate object and add an IBOutlet to the SourceList you just created (it's a standard *NSOutlineView*).
6. Switch to the implementation and choose an appropriate method where to put the INSSourceList initialization (in a Window Controller, the right method would be windowDidLoad). The correct way to initialize INSSourceList is by using its designated initializer: `+ (instancetype)sourceListInOutlineView:(NSOutlineView*)aView andDelegate:(id<INSSourceListDelegate>)aDelegate`. You just need to tell the SourceList where to put its data (the NSOutlineView you added in the previous step) and a Delegate object.
7. Implement all the required methods of the INSSourceListDelegate protocol and you're done.

Documentation
=============
A documentation generated by [appledoc](https://github.com/tomaz/appledoc) is available on this [page](http://help.inerziasoft.eu/INSSourceList/).

Project State
=============
The INSSourceList is currently in a **Release Candidate** state. You can use it freely in a stable application.

Other Stuff
=============

## What's Missing
The following features are planned:

* Drag and Drop support (now partial implemented)

## Special Thanks
* The StackOverflow community