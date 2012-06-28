//
//  AppDelegate.h
//  DocManager
//
//  Created by Studio on 4/11/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property BOOL isICloudAvailable;
@property BOOL applicationFirstRun;


@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
