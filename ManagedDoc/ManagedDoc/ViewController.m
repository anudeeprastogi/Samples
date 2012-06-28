//
//  ViewController.m
//  ManagedDoc
//
//  Created by Studio on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "DocDetailsViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize docTableView = _docTableView;
@synthesize docsArray = _docsArray;
@synthesize urlsForFileNames = _urlsForFileNames;
@synthesize notifications = _notifications;

#pragma mark - iCloud Container URL Methods

- (NSURL*)containerURL {
    
    static NSURL* url = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    });
    
    return url;
}

- (NSURL*)localURL {
    
    static NSURL* url = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    });
    
    return url;
}

- (BOOL)isCloudEnabled {
    
    return self.containerURL != nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.notifications = [NSMutableArray arrayWithCapacity:3];
    self.docsArray = [[NSMutableArray alloc]init];
    
    if (self.cloudEnabled) {
        [self listCloudFiles];
    } 
    else {
        [self listLocalFiles];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    for (id observer in self.notifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

- (void)listLocalFiles{
    
    NSLog(@"Listing local files");
    
    // get all the files
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.localURL includingPropertiesForKeys:nil options:0 error:nil];
        
    self.urlsForFileNames = [NSMutableDictionary dictionaryWithCapacity:[contents count]];
    
    for (NSURL* url in contents) {
        
        NSString* fileName = [url lastPathComponent];
        [self.docsArray addObject:fileName];
        [self.urlsForFileNames setValue:url forKey:fileName];
    }
    
    [self.docTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)listCloudFiles{

    NSLog(@"Listing cloud files");
    
    self.urlsForFileNames = [NSMutableDictionary dictionaryWithCapacity:100];
    NSMetadataQuery* query = [[NSMetadataQuery alloc] init];
    
    [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDataScope]];
    
    // We cannot look for the folder--must look for the contained DocumentMetadata.plist.
    [query setPredicate:[NSPredicate predicateWithFormat:@"%K like %@", NSMetadataItemFSNameKey,@"DocumentMetadata.plist"]];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSMetadataQueryDidFinishGatheringNotification object:query queue:nil usingBlock:^(NSNotification* notification) {
         
         NSLog(@"NSMetadataQuery finished gathering, found %d files",[query resultCount]);
        // what's in the iCloud container 
         NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtURL:self.containerURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey] options:0 errorHandler:nil];
         id object;
        
         NSLog(@"iCloud Container Contents:");
         while (object = [enumerator nextObject]) {
             NSLog(@"File URL Object %@\n", object);
         }
         NSLog(@"Done");
         
         // if we don't have any results, look at what is actually inside the iCloud container.
         if ([query resultCount] == 0) {
             
             // Now clear the container -- must be done inside a file coordinator
             [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:self.containerURL options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL *newURL) {
                  
                  [[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
              }];
         }
         [query enableUpdates];
     }];
    
    [self.notifications addObject:observer];
    
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSMetadataQueryDidUpdateNotification object:query queue:nil usingBlock:^(NSNotification *note) {
         
         NSLog(@"Update recieved. %d files found so far",[query resultCount]);
         [self processUpdate:query];
     }];
    
    [self.notifications addObject:observer];
    
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSMetadataQueryGatheringProgressNotification object:query queue:nil usingBlock:^(NSNotification *note) {
         
         NSLog(@"Progress notification recieved. %d files found so far",[query resultCount]);
         [self processUpdate:query];
     }];
    
    [self.notifications addObject:observer];
    
    [query startQuery];
}

- (void)processUpdate:(NSMetadataQuery*)query{
    
    [query disableUpdates];
    
    NSUInteger currentCount = [self.docsArray count];
    NSUInteger updateCount = [query resultCount];
    
    NSAssert2( updateCount >= currentCount,@"The number of files should never go down, "@"dropped from %d to %d",currentCount,updateCount);
    
    NSArray* newItems = [query.results subarrayWithRange:NSMakeRange(currentCount, updateCount - currentCount)];
    
    NSLog(@"New Items %@",newItems);
    
    [self addNewFilesToList:newItems];
    [query enableUpdates];

}

- (void)addNewFilesToList:(NSArray*)queryItems {
    
    NSLog(@"Adding new files");
    NSUInteger count = [queryItems count];
    if (count == 0) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (NSMetadataItem* item in queryItems) {
            
            NSURL* url = [item valueForAttribute:NSMetadataItemURLKey];
            NSURL* cloudURL = [url URLByDeletingLastPathComponent];
            
            NSFileCoordinator* coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            
            // always wrap any read/write operations in an appropriate coordinator
            [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL *newURL) {
                 
                 NSDictionary* dict = [NSDictionary dictionaryWithContentsOfURL:url];
                 NSString* name = [dict valueForKey:NSPersistentStoreUbiquitousContentNameKey];
                 
                [self.docsArray addObject:name];
                [self.urlsForFileNames setValue:cloudURL forKey:name];
                 
             }]; // end of coordinator block
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.docTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }); 
    
}

#pragma mark - 
#pragma mark - New Document Methods

- (NSString*)newUntitledDocumentName {
    
    NSInteger docCount = 1;     // Start with 1 and go from there.
    NSString* newDocName = nil;
    
    // At this point, the document list should be up-to-date.
    BOOL done = NO;
    while (!done) {
        newDocName = [NSString stringWithFormat:@"Document %d",docCount];
        
        // Look for an existing document with the same name. If one is
        // found, increment the docCount value and try again.
        BOOL nameExists = NO;
        for (NSString* aFileName in self.docsArray) {
            if ([aFileName isEqualToString:newDocName]) {
                docCount++;
                nameExists = YES;
                break;
            }
        }
        // If the name wasn't found, exit the loop.
        if (!nameExists)
            done = YES;
    }
    return newDocName;
}

- (UIManagedDocument*)createDocument:(NSString*)fileName {
    
    // This instantiates a UIManagedDocument object, But does not save or open it (does not create or read the underlying persistent store).
    NSLog(@"File Name %@",fileName);
    NSDictionary *options;
    
    if (self.cloudEnabled) {
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                   [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                   fileName, NSPersistentStoreUbiquitousContentNameKey,
                   self.containerURL, NSPersistentStoreUbiquitousContentURLKey,
                   nil];   
    } else {
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                   [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                   nil];   
    }
    
    NSURL* url = [self.urlsForFileNames valueForKey:fileName];

    // if we don't have a valid URL, create a local url
    if (url == nil) {
        
        url = [self.localURL URLByAppendingPathComponent:fileName];
        [self.urlsForFileNames setValue:url forKey:fileName];
    }
    
    // Now Create our document
    UIManagedDocument* document = [[UIManagedDocument alloc] initWithFileURL:url];
    document.persistentStoreOptions = options;
        
    return document;
}

- (IBAction)addDocClicked:(id)sender{
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSString *newDocName = [self newUntitledDocumentName];
    NSURL* documentURL = [self.localURL URLByAppendingPathComponent:newDocName];
    UIManagedDocument* document = [self createDocument:newDocName];

    [document saveToURL:documentURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
         
         if (success == NO) {
             
             // we could really use more robust error handling here note that we have no idea what the problem is.
             // delete any partially saved data
             [[NSFileManager defaultManager] removeItemAtURL:documentURL error:nil];
             // and just exit
             return;
         }
         
         NSArray* indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.docsArray count] inSection:0]];
         
        [self.docsArray addObject:newDocName];
         
         [self.docTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
         
         // if we're cloud enabled, move to the cloud container
         if (self.cloudEnabled) {
             
             NSURL* cloudURL = [self.containerURL URLByAppendingPathComponent:newDocName];
             
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 
                 NSError* error;
                 if (![[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:documentURL destinationURL:cloudURL error:&error]) {
                     
                     [NSException raise:NSGenericException format:@"Error moving to iCloud container: %@",error.localizedDescription];
                 }
                 
                 [self.urlsForFileNames setValue:cloudURL forKey:newDocName];
                 
             });
         }
     }];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark - 
#pragma mark - New Document Methods end

#pragma mark - 
#pragma mark - UITableView Datasource and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{    
    
    return [self.docsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString* docCell = @"DocCell";

    UITableViewCell *newCell = [tableView dequeueReusableCellWithIdentifier:docCell];
    if (!newCell)
        newCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:docCell];
    
    if (!newCell)
        return nil;
    
    NSString* fileName = [self.docsArray objectAtIndex:indexPath.row];
    newCell.textLabel.text = fileName;
    
    return newCell;
}

#pragma mark - 
#pragma mark - UITableView Datasource and Delegate end

#pragma mark - 
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"DocDetails"]) {
        
        DocDetailsViewController* destination = segue.destinationViewController;
        
        UITableViewCell* cell = sender;
        NSString* fileName = cell.textLabel.text;
        
        UIManagedDocument* document = [self createDocument:fileName];
        
        [document openWithCompletionHandler:^(BOOL success) {
            
            if (success == NO) {
                [NSException raise:NSGenericException format:@"Could not open the file %@ at %@", fileName, document.fileURL];
            }
            
            destination.document = document;
            destination.docFileName = fileName;
            
            if ([destination isViewLoaded]) {
                [destination configureDocument];
            }
        }];
    }
}

#pragma mark - 
#pragma mark - Segue end

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
