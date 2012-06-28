//
//  ViewController.h
//  PreferencesIniCloud
//
//  Created by Studio on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(nonatomic,strong) IBOutlet UILabel *keyLabel;
@property(nonatomic,strong) IBOutlet UILabel *valueLabel;
@property(nonatomic,strong) IBOutlet UISlider *slider;

-(IBAction)sliderValueChanged:(id)sender;

@end
