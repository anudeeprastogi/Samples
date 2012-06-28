//
//  DocDetailsViewController.m
//  ManagedDoc
//
//  Created by Studio on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocDetailsViewController.h"

@interface DocDetailsViewController ()

@end

@implementation DocDetailsViewController

@synthesize docTitleLbl = _docTitleLbl;
@synthesize docTextView = _docTextView;
@synthesize docFileName = _docName;
@synthesize document = _document;

@synthesize docObject = _docObject;
@synthesize notificationObservers = _notificationObservers;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (self.document != nil) {
        [self configureDocument];
    }
}

- (void)configureDocument {
    
    NSLog(@"Configuring Document");
        
    NSManagedObjectContext* moc = self.document.managedObjectContext;
    moc.mergePolicy = NSRollbackMergePolicy;
    
    // Check to see if we have a TextEntry
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"DocEntry"];
    
    // Sort in date order, oldest at the end
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"syncDate" ascending:YES];
    request.sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    NSArray* results = [moc executeFetchRequest:request error:nil];
    
    NSLog(@"Results %d",[results count]);
    
    if ([results count] == 0) {
        
        [self createDocEntry];
    } 
    else {
        
        // we may end up with two or more entries if two seperate versions of the app create one before saving their updates to the cloud. In this case, we need to manually select the newest and delete the others.
        
        if ([results count] > 1) {
            
            NSLog(@"Too many entries, accepting the last one and deleting the rest");
        }
        
        self.docObject = [results lastObject];
        NSLog(@"Title %@",[self.docObject syncDate]);
        
        NSLog(@"Assigning Doc entry: (%@, %@)", self.docObject.docTitle, self.docObject.docText);
        
        self.docTitleLbl.text = self.docObject.docTitle;
        self.docTextView.text = self.docObject.docText;
        
        // now remove all but the last object
        for (int i = 0; i < [results count] - 1; i++) {
            
            NSLog(@"Deleting %d of %d", i + 1, [results count]);
            [moc deleteObject:[results objectAtIndex:i]];
        }
    }
    
    self.notificationObservers = [[NSMutableArray alloc] initWithCapacity:2];
        
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:moc.persistentStoreCoordinator queue:nil usingBlock:^(NSNotification *note) {
         
         NSLog(@"Updating content from iCloud");
        
         // This should work, but seems to create race conditions
         [moc performBlock:^{
             
             NSLog(@"Merging changes");
             [moc mergeChangesFromContextDidSaveNotification:note];
             
             self.docTitleLbl.text = self.docObject.docTitle;
             self.docTextView.text = self.docObject.docText;
             
             NSLog(@"New Text Entry: %@, %@",self.docObject.docTitle, self.docObject.docText);
         }];
    }];
    
    [self.notificationObservers addObject:observer];
    
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIDocumentStateChangedNotification object:self queue:nil usingBlock:^(NSNotification *note) {
         
         UIDocumentState state = self.document.documentState;
        NSLog(@"State %d",state);
         if (state == 0) {
             
             NSLog(@"Document State Normal");
             
             dispatch_async( dispatch_get_main_queue(), ^{
                 
                 self.docTextView.editable = YES;
             });
         }
         
         if (state & UIDocumentStateClosed) {
             
             NSLog(@"Document Closed!");
             
             dispatch_async( dispatch_get_main_queue(), ^{
                 
                 [self.navigationController popViewControllerAnimated:YES];
             });
         }
         
         if (state & UIDocumentStateEditingDisabled) {
             
             NSLog(@"Document Editing Disabled");
             
             dispatch_async( dispatch_get_main_queue(), ^{
                 
                 self.docTextView.editable = NO;
             });
         }
         
         if (state & UIDocumentStateSavingError) {
             NSLog(@"Saving Error Occurred");
         }
         
         if (state & UIDocumentStateInConflict) {
             NSLog(@"Document in conflict");
         }
     }];
    
    [self.notificationObservers addObject:observer];    
    [self.docTextView becomeFirstResponder];

}

- (void)createDocEntry {
    
    NSLog(@"Creating a new text entry");
    
    NSManagedObjectContext* moc = self.document.managedObjectContext;
    
    DocEntry* entry = [NSEntityDescription insertNewObjectForEntityForName:@"DocEntry" inManagedObjectContext:moc];
    
    entry.docTitle = self.docFileName;
    entry.docText = @"";
    
    // Give it an old date so it always loses conflicts
    entry.syncDate = [NSDate dateWithTimeIntervalSince1970:0];
    
    self.docObject = entry;
    self.docTitleLbl.text = entry.docTitle;
    self.docTextView.text = entry.docText;
    
    NSError* error;
    if (![moc save:&error]) {
        
        [NSException raise:NSInternalInconsistencyException format:[error localizedDescription]];
    }
    else {
        NSLog(@"Successfull Creation of Doc Entry");
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    for (id observer in self.notificationObservers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
    
    // if we don't have any changes, just quit
    
    if ([self.docObject.docText isEqualToString:self.docTextView.text]) {
        return;
    }
    
    // save any changes
    self.docObject.docTitle = self.docTitleLbl.text;
    self.docObject.docText = self.docTextView.text;
    self.docObject.syncDate = [NSDate date];
    
    // as long as editing is enabled and we have unsaved changes, save the results
    if ((self.document.documentState & UIDocumentStateEditingDisabled) != UIDocumentStateEditingDisabled) {
        
        [self.document saveToURL:self.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            
            if (success) {
                NSLog(@"%@ saved", self.docFileName); 
            } 
            else {
                NSLog(@"%@ unable to save", self.docFileName);
            }
        }];
    }
}

- (void)viewDidUnload
{
    [self setDocTitleLbl:nil];
    [self setDocTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
