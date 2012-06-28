//
//  ViewController.h
//  ManagedDoc
//
//  Created by Studio on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (strong,nonatomic) IBOutlet UITableView *docTableView;
@property (strong,nonatomic) NSMutableArray *docsArray;

@property (readonly, nonatomic, getter = isCloudEnabled) BOOL cloudEnabled;

@property (strong, nonatomic) NSMutableDictionary* urlsForFileNames;
@property (strong, nonatomic) NSMutableArray* notifications;

@property (readonly, nonatomic) NSURL* containerURL;
@property (readonly, nonatomic) NSURL* localURL;

- (IBAction)addDocClicked:(id)sender;

@end
