//
//  ViewController.h
//  DocManager
//
//  Created by Studio on 4/11/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>{
    
     NSMetadataQuery *_query;
}

@property (strong,nonatomic) IBOutlet UITableView *docListTableView;
@property (strong,nonatomic) NSMutableArray *docArray;
@property (strong,nonatomic) NSMutableArray *myDocArray;
@property (strong,nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)addDocumentClicked:(id)sender;

-(void)addContentInCoreData;
-(void)addContentInFile;


@end
