//
//  DocCell.h
//  DocManager
//
//  Created by Anudeep Rastogi on 4/12/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocCell : UITableViewCell

@property (strong,nonatomic) IBOutlet UILabel *docTitleLabel;
@property (strong,nonatomic) IBOutlet UIImageView *docImgView;

@end
