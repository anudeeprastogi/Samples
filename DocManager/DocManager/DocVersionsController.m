//
//  DocVersionsController.m
//  DocManager
//
//  Created by Studio on 4/13/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import "DocVersionsController.h"
#import "DocVersionsCell.h"

@interface DocVersionsController ()

@end

@implementation DocVersionsController

@synthesize versionsTableView = _versionsTableView;
@synthesize versionsArray = _versionsArray;

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
}

#pragma -
#pragma TableView methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    //NSLog(@"Saved Count %d",[self.savedGamesArray count]);
    //return [self.allPhotosURLArray count];
    
    return [self.versionsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"DocVersionsCell";
    
    DocVersionsCell *cell = (DocVersionsCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DocVersionsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView setSeparatorColor:[UIColor whiteColor]];
    
    return 40.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    cell.selectedBackgroundView.backgroundColor=[UIColor whiteColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSLog(@"Row Selected %d",indexPath.row);
    
    
}

#pragma -
#pragma TableView methods end


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
