//
//  ViewController.m
//  DocManager
//
//  Created by Studio on 4/11/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import "DocListViewController.h"
#import "DocDetailsViewController.h"
#import "AppDelegate.h"
#import "DocCell.h"
#import "MyDocuments.h"

@interface DocListViewController ()
@end

#define RootDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]

NSString *DOCExtension = @"doc";
NSString *DocumentsDirectoryName = @"Documents";

@implementation DocListViewController

@synthesize docListTableView = _docListTableView;
@synthesize docArray = _docArray;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize myDocArray = _myDocArray;

#pragma mark -
#pragma mark - Records Addition in Core Data

- (NSArray *)sortArray:(NSArray *)originalArray {

    return [originalArray sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2){
        NSString *index1 = [(MyDocuments *)obj1 docIndex];
        NSString *index2 = [(MyDocuments *)obj2 docIndex];
        return [index1 compare:index2 options:NSNumericSearch];
    }];
}

-(NSArray *)coreDataEntries{
    
    NSArray *sortedArrayByIndex;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyDocuments" inManagedObjectContext:[RootDelegate managedObjectContext]];
    [request setEntity:entity];
    
    NSError *error = nil;
    NSArray *entries = [[RootDelegate managedObjectContext] executeFetchRequest:request error:&error];
    
    if ([entries count]) {
        sortedArrayByIndex = [NSArray arrayWithArray:[self sortArray:entries]];
    }
        
    return sortedArrayByIndex;
}

-(void)addRecordsInCoreData{
    
    dispatch_async(dispatch_queue_create("com.app.loadData",NULL),^{
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"DocumentsDB" ofType:@"plist"];    
        NSDictionary *rootDict = [[NSDictionary alloc]initWithContentsOfFile:path];
       
        dispatch_async(dispatch_get_main_queue(),^{
            
            NSDictionary *contentDict = [rootDict valueForKey:@"Docs"];
            [contentDict enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) 
             {
                 NSDictionary *dataDict = (NSDictionary *)object;
                 int index = [[dataDict valueForKey:@"docIndex"] intValue];
                 
                 UIImage *docImage;
                 if (index == 1) {docImage = [UIImage imageNamed:@"redStar"];}
                 else if (index == 2) {docImage = [UIImage imageNamed:@"goldStar"];}
                 else if (index == 3) {docImage = [UIImage imageNamed:@"blueStar"];}
                 
                 [[RootDelegate managedObjectContext] performBlockAndWait:^{
                 
                     MyDocuments *myDocument = [NSEntityDescription insertNewObjectForEntityForName:@"MyDocuments" inManagedObjectContext:[RootDelegate managedObjectContext]];
                     [myDocument setTimestamp:[NSDate date]];
                     [myDocument setTitle:[dataDict valueForKey:@"titleName"]];
                     [myDocument setText:[dataDict valueForKey:@"content"]];
                     [myDocument setMyImage:UIImagePNGRepresentation(docImage)];
                     [myDocument setDocIndex:[dataDict valueForKey:@"docIndex"]];
                 }];
             }];
            
            NSError *error = nil;
            if(![[RootDelegate managedObjectContext] save:&error]){
                NSLog(@"Error saving Editions - error:%@",error);
            }
            else {
                [self addMyDocs];
            }            
        });
    });
}

-(void)addMyDocs{
    
    self.navigationItem.rightBarButtonItem.enabled = NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Create the new URL object on a background queue.
    
        NSArray *dataEntries = [self coreDataEntries];
        NSLog(@"Core Data Entries %d",[dataEntries count]);
    
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *saveURL = [fm URLForUbiquityContainerIdentifier:nil];
        saveURL = [saveURL URLByAppendingPathComponent:DocumentsDirectoryName isDirectory:YES];

        // Perform the remaining tasks on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
        
            if (saveURL) {
                
                [self.myDocArray removeAllObjects];
                for (MyDocuments *coreDoc in dataEntries) {
                    
                    NSString *newDocName = [coreDoc title];
                    NSURL *myDocumentURL = [saveURL URLByAppendingPathComponent:newDocName];
                    
                    NSDictionary *myDict = [NSDictionary dictionaryWithObjectsAndKeys:coreDoc,@"CoreObject",myDocumentURL,@"DocURL", nil];
                    [self.myDocArray addObject:myDict];
                }
                
            [self.docListTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }    
            self.navigationItem.rightBarButtonItem.enabled = YES;
        });
    });
}

#pragma mark -
#pragma mark - Records Addition in Core Data

- (void)refreshUI:(NSNotification*)note {
    
    NSLog(@"Underlying data changed ... refreshing!");

    if (!self.myDocArray) {
        self.myDocArray = [[NSMutableArray alloc]init];        
    }
    
    if ([RootDelegate applicationFirstRun]) {
        NSLog(@"Adding in Core Data");
        [self addRecordsInCoreData];
    }
    else {
        [self addMyDocs];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.docArray) {
        self.docArray = [[NSMutableArray alloc]init];        
    }

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshUI:) name:@"CoreDataChanged" object:[[UIApplication sharedApplication] delegate]];

    [self setupAndStartQuery];
    
	// Do any additional setup after loading the view, typically from a nib.
}

#pragma mark -
#pragma mark - NSMetadataQuery Methods

- (NSMetadataQuery*)textDocumentQuery {
    
    NSMetadataQuery* aQuery = [[NSMetadataQuery alloc] init];
    
    if (aQuery) {
        
        // Search the Documents subdirectory only.
        [aQuery setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
        
        // Add a predicate for finding the documents.
        NSString* filePattern = [NSString stringWithFormat:@"*.%@",DOCExtension];
        [aQuery setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@",NSMetadataItemFSNameKey, filePattern]];
    }
    
    return aQuery;
}

- (void)setupAndStartQuery {
    // Create the query object if it does not exist.
    if (!_query)
        _query = [self textDocumentQuery];
    
    // Register for the metadata query notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFiles:) name:NSMetadataQueryDidFinishGatheringNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFiles:) name:NSMetadataQueryDidUpdateNotification object:nil];
    
    // Start the query and let it run.
    [_query startQuery];
    
}

- (void)processFiles:(NSNotification*)aNotification {
    NSMutableArray *discoveredFiles = [NSMutableArray array];
    
    // Always disable updates while processing results.
    [_query disableUpdates];
    
    // The query reports all files found, every time.
    NSArray *queryResults = [_query results];
    for (NSMetadataItem *result in queryResults) {
        NSURL *fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        NSNumber *aBool = nil;
        
        // Don't include hidden files.
        [fileURL getResourceValue:&aBool forKey:NSURLIsHiddenKey error:nil];
        if (aBool && ![aBool boolValue])
            [discoveredFiles addObject:fileURL];
    }
    
    // Update the list of documents.
    [self.docArray removeAllObjects];
    [self.docArray addObjectsFromArray:discoveredFiles];
    [self.docListTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // Reenable query updates.
    [_query enableUpdates];
}

#pragma mark -
#pragma mark - NSMetadataQuery Methods end


#pragma mark -
#pragma mark - ADD New Doc Methods

- (NSString*)newUntitledDocumentNameWithType:(NSString *)type {
   
    NSInteger docCount = 1;     // Start with 1 and go from there.
    NSString* newDocName = nil;
    
    NSMutableArray *searchArray = [[NSMutableArray alloc]init];
    if ([type isEqualToString:@"Doc"]) {
        searchArray = self.docArray;
    }
    else if ([type isEqualToString:@"My Doc"]) {
        
        for (NSDictionary *myDict in self.myDocArray) {
            [searchArray addObject:[myDict valueForKey:@"DocURL"]];
        }
    }
    // At this point, the document list should be up-to-date.
    BOOL done = NO;
    while (!done) {
        
        if ([type isEqualToString:@"Doc"]) {newDocName = [NSString stringWithFormat:@"%@ %d.%@",type,docCount, DOCExtension];}
        else if ([type isEqualToString:@"My Doc"]) {newDocName = [NSString stringWithFormat:@"%@ %d",type,docCount];}
        
        // Look for an existing document with the same name. If one is
        // found, increment the docCount value and try again.
        BOOL nameExists = NO;
        for (NSURL* aURL in searchArray) {
            if ([[aURL lastPathComponent] isEqualToString:newDocName]) {
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


-(void)addContentInFile{
    
    self.navigationItem.rightBarButtonItem.enabled = NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Create the new URL object on a background queue
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *newDocumentURL = [fm URLForUbiquityContainerIdentifier:nil];
        
        // New Document Name function
        NSString *newDocName = [self newUntitledDocumentNameWithType:@"Doc"];
        
        newDocumentURL = [newDocumentURL URLByAppendingPathComponent:DocumentsDirectoryName isDirectory:YES];
        newDocumentURL = [newDocumentURL URLByAppendingPathComponent:newDocName];
        
        // Perform the remaining tasks on the main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Update the data structures and table.
            if (newDocumentURL) {
                
                [self.docArray addObject:newDocumentURL];
                
                NSLog(@"Doc URL %@ Count %d",newDocumentURL,[self.docArray count]);
                
                // Update the table.
                NSIndexPath* newCellIndexPath = [NSIndexPath indexPathForRow:([self.docArray count] - 1)  inSection:1];
                
                NSLog(@"Index Path %d %d",newCellIndexPath.row,newCellIndexPath.section);
                
                [self.docListTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newCellIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];            
                [self.docListTableView selectRowAtIndexPath:newCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                
                NSIndexPath *cellPath = [self.docListTableView indexPathForSelectedRow];
                DocCell *theCell = (DocCell *)[self.docListTableView cellForRowAtIndexPath:cellPath];
                NSURL *theURL = [self.docArray objectAtIndex:[cellPath row]];
                
                // Assign the URL to the detail view controller and set the title of the view controller to the doc name. Push the details controller on the current view.
                
                DocDetailsViewController *detailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DocDetailsViewController"];
                
                detailsVC.detailItem = theURL;
                detailsVC.navigationItem.title = theCell.textLabel.text;
                
                [self.navigationController pushViewController:detailsVC animated:YES];
            }
            // Reenable the Add button.
            self.navigationItem.rightBarButtonItem.enabled = YES;
        });
    });
}

-(void)addContentInCoreData{

    NSString *newMyDocTitle =[self newUntitledDocumentNameWithType:@"My Doc"];
    NSString *nextDocIndex = @"0";

    if ([self.myDocArray count] >= 1) {
        
        NSDictionary *lastDict = [self.myDocArray lastObject];
        MyDocuments *lastDoc = [lastDict valueForKey:@"CoreObject"];
        nextDocIndex = [NSString stringWithFormat:@"%d", [[lastDoc docIndex] intValue]+1];
    }
   
    int imageIndex = [nextDocIndex intValue] % 3;
    
    UIImage *docImage;
    if (imageIndex == 1) {docImage = [UIImage imageNamed:@"redStar"];}
    else if (imageIndex == 2) {docImage = [UIImage imageNamed:@"goldStar"];}
    else if (imageIndex == 3) {docImage = [UIImage imageNamed:@"blueStar"];}
    else {docImage = [UIImage imageNamed:@"whiteStar"];}
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:newMyDocTitle,@"titleName",@"No Preloaded Text",@"content",nextDocIndex,@"docIndex", nil];

    [[RootDelegate managedObjectContext] performBlockAndWait:^{
        
        MyDocuments *myDocument = [NSEntityDescription insertNewObjectForEntityForName:@"MyDocuments" inManagedObjectContext:[RootDelegate managedObjectContext]];
        [myDocument setTimestamp:[NSDate date]];
        [myDocument setTitle:[dataDict valueForKey:@"titleName"]];
        [myDocument setText:[dataDict valueForKey:@"content"]];
        [myDocument setMyImage:UIImagePNGRepresentation(docImage)];
        [myDocument setDocIndex:[dataDict valueForKey:@"docIndex"]];
    }];

    NSError *error = nil;
    if(![[RootDelegate managedObjectContext] save:&error]){
        NSLog(@"Error saving Editions - error:%@",error);
    }
    else {
        [self addMyDocs];
    }            
}

-(IBAction)addDocumentClicked:(id)sender{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please pick a category for document" message:nil delegate:self cancelButtonTitle:@"My Docs" otherButtonTitles:@"Docs", nil];
    [alert show];        
}

#pragma mark -
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
     
        [self addContentInCoreData];
    }
    
    if (buttonIndex == 1) {
        
        [self addContentInFile];
    }
}

#pragma mark -
#pragma mark - UIAlertViewDelegate end


#pragma mark -
#pragma mark - ADD New Doc Methods end


#pragma -
#pragma TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{

    return 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    if (section == 0) {
        return @"My Docs";
    }
    else {
        return @"Docs";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (section == 0) {
        return [self.myDocArray count];
    }
    else {
        return [self.docArray count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"DocCell";
    
    DocCell *cell = (DocCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DocCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Get the doc at the specified row.
    NSURL *fileURL;
    
    cell.docImgView.image = [UIImage imageNamed:@"whiteStar"];
    
        
    if (indexPath.section == 0) {
        
        NSDictionary *myDict = [self.myDocArray objectAtIndex:indexPath.row];
        MyDocuments *myDoc = [myDict valueForKey:@"CoreObject"];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // Load image in background
            UIImage *labelImg = [UIImage imageWithData:[myDoc myImage]];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Assign the loaded image to cell
                cell.docImgView.image = labelImg;
            });
        });

        fileURL = [myDict valueForKey:@"DocURL"];
    }
    else{
        fileURL = [self.docArray objectAtIndex:[indexPath row]];
    }
    
    // Configure the cell.
    cell.docTitleLabel.text = [[fileURL lastPathComponent] stringByDeletingPathExtension];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"Row Selected %d in Section %d",indexPath.row,indexPath.section);
    
    // Find the correct dictionary from the documents array.
    NSIndexPath *cellPath = [self.docListTableView indexPathForSelectedRow];
    DocCell *theCell = (DocCell *)[self.docListTableView cellForRowAtIndexPath:cellPath];
    NSURL *theURL;
    
    DocDetailsViewController *detailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DocDetailsViewController"];

    if (indexPath.section == 0) {
        NSDictionary *myDict = [self.myDocArray objectAtIndex:indexPath.row];
        theURL = [myDict valueForKey:@"DocURL"];
        detailsVC.myDoc = [myDict valueForKey:@"CoreObject"];
        // You will have to change the text too in DocDetailsViewController so that Core Data has the updated text, or simply check if there is any text in the URL and if it is NULL then only assign the default text
    }
    else {
        theURL = [self.docArray objectAtIndex:[cellPath row]];
    }
    
    // Assign the URL to the detail view controller and
    // set the title of the view controller to the doc name.

    detailsVC.detailItem = theURL;
    detailsVC.navigationItem.title = theCell.textLabel.text;
    
    [self.navigationController pushViewController:detailsVC animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Deleted Row %d",indexPath.row);
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
       
        if (indexPath.section == 0) {
            // Delete from Core Data
            
            NSLog(@"Deleting frm Core Data");
            
            NSError *error;
            NSManagedObjectContext *context = [RootDelegate managedObjectContext];
            
            NSDictionary *deleteDict = [self.myDocArray objectAtIndex:indexPath.row];
            MyDocuments *deleteDoc = (MyDocuments *)[deleteDict valueForKey:@"CoreObject"];
            
            NSLog(@"Core Data Entry deleted %@ %@ %@",[deleteDoc title],[deleteDoc text],[deleteDoc docIndex]);
            
            [context deleteObject:deleteDoc];
            if (![context save:&error]) {
                
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
            
            [self.myDocArray removeObject:deleteDict];

        }
        else{
         
            // Delete from Doc Directory
            NSURL *fileURL = [self.docArray objectAtIndex:[indexPath row]];
            
            // Don't use file coordinators on the app's main queue.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                NSFileCoordinator *fc = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                
                [fc coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting error:nil 
                                    byAccessor:^(NSURL *newURL) {
                                        NSFileManager *fm = [[NSFileManager alloc] init];
                                        [fm removeItemAtURL:newURL error:nil];
                                    }];
            });
            
            // Remove the URL from the documents array.
            [self.docArray removeObjectAtIndex:[indexPath row]];

        }
                
        // Update the table UI. This must happen after
        // updating the documents array.
        [self.docListTableView beginUpdates];
        [self.docListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.docListTableView endUpdates];

    }
}

#pragma -
#pragma - TableView methods end

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
