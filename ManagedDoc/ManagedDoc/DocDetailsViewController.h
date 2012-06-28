//
//  DocDetailsViewController.h
//  ManagedDoc
//
//  Created by Studio on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DocEntry.h"

@interface DocDetailsViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *docTitleLbl;
@property (strong, nonatomic) IBOutlet UITextView *docTextView;

@property (strong, nonatomic) NSString *docFileName;
@property (strong, nonatomic) UIManagedDocument* document;
@property (strong, nonatomic) DocEntry* docObject;
@property (strong, nonatomic) NSMutableArray* notificationObservers;

- (void)configureDocument;

@end
