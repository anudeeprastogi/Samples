//
//  Documents.h
//  DocManager
//
//  Created by Anudeep Rastogi on 4/12/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DocumentsDelegate;

@interface Documents : UIDocument

@property (copy, nonatomic) NSString* documentText;
@property (weak, nonatomic) id<DocumentsDelegate> delegate;

@end

@protocol DocumentsDelegate <NSObject>
@optional
- (void)documentContentsDidChange:(Documents *)document;
@end