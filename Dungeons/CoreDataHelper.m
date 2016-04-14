//
//  CoreDataHelper.m
//  Dungeons
//
//  Created by Andrew Meckling on 2016-04-13.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import "CoreDataHelper.h"

@implementation CoreDataHelper
//Based on tutorial from http://www.informit.com/articles/article.aspx?p=2160898&seqNum=4
#define debug 1

#pragma mark - FILES
NSString *storeFilename = @"Grocery-Dude.sqlite";

#pragma mark - PATHS

//Lets CoreData know where in the file system persistent store files are located
//Returns an NSString representing the path to the application's documents directory
- (NSString *)applicationDocumentsDirectory {
    if (debug==1) { //Shows what method is running; useful for seeing order of execution of methods
        NSLog(@"Running %@ '%@'", self.class,NSStringFromSelector(_cmd));
    }
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES) lastObject];
}

//Appends a directory called Stores to the application's documents directory and then returns it (as NSURL)
- (NSURL *)applicationStoresDirectory {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSURL *storesDirectory =
    [[NSURL fileURLWithPath:[self applicationDocumentsDirectory]]
     URLByAppendingPathComponent:@"Stores"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[storesDirectory path]]) {
        NSError *error = nil;
        if ([fileManager createDirectoryAtURL:storesDirectory
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error]) {
            if (debug==1) {
                NSLog(@"Successfully created Stores directory");}
        }
        else {NSLog(@"FAILED to create Stores directory: %@", error);}
    }
    return storesDirectory;
}

//Appends the persistent store filename to the store's directory path - providing a full path to the persistent store file
- (NSURL *)storeURL {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return [[self applicationStoresDirectory]
            URLByAppendingPathComponent:storeFilename];
}

#pragma mark - SETUP

//runs when a CoreDataHelper is instantiated (ie. constructor)
- (id)init {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    self = [super init];
    if (!self) {return nil;}
    
    //points to managed object model, which is initiated from all available data model files (object graphs) found in the main bundle with this function
    _model = [NSManagedObjectModel mergedModelFromBundles:nil]; //possible to pass an NSArray of NSBundles to merge multiple models here
    //Another way to initialize managed object model is to specify the exact model file to use.
    //As opposed to merging bundles
    //eg.
    //_model = [[NSManagedObjectModel alloc] initWithContentsOfURL: [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"]];.
    
    
    //Persistent store files for _coordinator will be added by the setupCoreData method
    _coordinator = [[NSPersistentStoreCoordinator alloc]
                    initWithManagedObjectModel:_model]; //points to a persistent store coordinator
    
    //points to a managed object context
    //Will need a context on the main thread whenever you have a data-driven user interface; (for now, the main thread context will do)
    //Configured to use the existing _coordinator pointer to the persistent store coordinator
    _context = [[NSManagedObjectContext alloc]
                initWithConcurrencyType:NSMainQueueConcurrencyType]; //Type tells it to run on "Main" thread queue
    
    [_context setPersistentStoreCoordinator:_coordinator];
    return self;
}

- (void)loadStore {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if (_store) {return;} // Don't load store if it's already loaded
    NSError *error = nil;
    _store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType //adds SQLite persistent store to _store
                                        configuration:nil
                                                  URL:[self storeURL] //storeURL of the persistent store is the one returned by the methods created previously
                                              options:nil error:&error];
    if (!_store) {NSLog(@"Failed to add store. Error: %@", error);abort();}
    else         {if (debug==1) {NSLog(@"Successfully added store: %@", _store);}}
}

- (void)setupCoreData {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [self loadStore];
    //method will be expanded later "in the book" as more functionality is added
}

#pragma mark - SAVING
//Called whenever you would like to save changes from the _context to the _store
- (void)saveContext {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    if ([_context hasChanges]) {
        NSError *error = nil;
        if ([_context save:&error]) { //easy as just sending the context a save: message
            NSLog(@"_context SAVED changes to persistent store");
        } else {
            NSLog(@"Failed to save _context: %@", error);
        }
    } else {
        NSLog(@"SKIPPED _context save, there are no changes!");
    }
}

@end
