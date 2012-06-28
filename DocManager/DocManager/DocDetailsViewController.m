//
//  DocDetailsViewController.m
//  DocManager
//
//  Created by Studio on 4/13/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import "DocDetailsViewController.h"
#import "AppDelegate.h"

@interface DocDetailsViewController ()

@end

#define RootDelegate (AppDelegate *)[[UIApplication sharedApplication] delegate]

@implementation DocDetailsViewController
@synthesize textView = _textView;
@synthesize document = _document;
@synthesize detailItem = _detailItem;
@synthesize myDoc = _myDoc;

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
    
    self.title = [[self.detailItem lastPathComponent] stringByDeletingPathExtension];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Clear out the text view contents.
    self.textView.text = @"";
    
    // show text from Core Data and save any changes to the managed object
    
    // Create the document and assign the delegate.

    _document = [[Documents alloc] initWithFileURL:self.detailItem];
    _document.delegate = self;
    
    // If the file exists, open it; otherwise, create it.
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self.detailItem path]])
        [_document openWithCompletionHandler:nil];
    else
        // Save the new document to disk.
        [_document saveToURL:self.detailItem forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
    
    // Register for the keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    if (_myDoc != NULL) {
        _document.documentText = [_myDoc text];
        self.textView.text = [_myDoc text];
    }
}

- (void)documentContentsDidChange:(Documents *)document {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = document.documentText;
        
        // Update changes in the managed object
        if (_myDoc != NULL) {
            [_myDoc setText:self.textView.text];
            NSError *error = nil;
            if(![[RootDelegate managedObjectContext] save:&error]){
                NSLog(@"Error saving Editions - error:%@",error);
            }
            
        }
    });
}

- (void)keyboardWillShow:(NSNotification*)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    
    CGRect kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    UIEdgeInsets insets = self.textView.contentInset;
    insets.bottom += kbSize.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        self.textView.contentInset = insets;
    }];
}

- (void)keyboardWillHide:(NSNotification*)aNotification {
   
    NSDictionary* info = [aNotification userInfo];
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // Reset the text view's bottom content inset.
    UIEdgeInsets insets = self.textView.contentInset;
    insets.bottom = 0;
    
    [UIView animateWithDuration:duration animations:^{
        self.textView.contentInset = insets;
    }];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSString* newText = self.textView.text;
    _document.documentText = newText;
    
    // Close the document.
    [_document closeWithCompletionHandler:nil];
    
    // Unregister for the keyboard notifications.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
