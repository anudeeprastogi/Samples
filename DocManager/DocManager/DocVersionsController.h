//
//  DocVersionsController.h
//  DocManager
//
//  Created by Studio on 4/13/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocVersionsController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (strong,nonatomic) IBOutlet UITableView *versionsTableView;
@property (strong,nonatomic) NSMutableArray *versionsArray;

@end
