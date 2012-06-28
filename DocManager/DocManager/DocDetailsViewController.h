//
//  DocDetailsViewController.h
//  DocManager
//
//  Created by Studio on 4/13/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Documents.h"
#import "MyDocuments.h"

@interface DocDetailsViewController : UIViewController<DocumentsDelegate>

@property (strong,nonatomic) NSURL *detailItem;
@property (strong,nonatomic) Documents *document;
@property (strong, nonatomic) MyDocuments *myDoc;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
