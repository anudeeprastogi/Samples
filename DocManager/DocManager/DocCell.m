//
//  DocCell.m
//  DocManager
//
//  Created by Anudeep Rastogi on 4/12/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import "DocCell.h"

@implementation DocCell

@synthesize docTitleLabel = _docTitleLabel;
@synthesize docImgView = _docImgView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
