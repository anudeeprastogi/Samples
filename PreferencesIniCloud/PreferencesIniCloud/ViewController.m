//
//  ViewController.m
//  PreferencesIniCloud
//
//  Created by Studio on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize keyLabel = _keyLabel;
@synthesize valueLabel = _valueLabel;
@synthesize slider = _slider;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultSliderValue =[NSString stringWithFormat:@"%f",[defaults floatForKey:@"SliderValue"]];

    self.slider.value = [defaults floatForKey:@"SliderValue"];
    self.valueLabel.text = defaultSliderValue;
        
    [self checkStore];
}

-(IBAction)sliderValueChanged:(id)sender{
    
    NSLog(@"Changed Value %f",[self.slider value]);
        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:self.slider.value] forKey:@"SliderValue"];
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    if (store) {
        NSLog(@"iCloud Store Available");
        [store setObject:[NSNumber numberWithFloat:self.slider.value] forKey:@"SliderValue"];
    }

    self.valueLabel.text = [NSString stringWithFormat:@"%f",self.slider.value];
}

-(void)checkStore{
    
    NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
    NSLog(@"Checking Store %@",store);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateKVStoreItems:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
    [store synchronize];
}

- (void)updateKVStoreItems:(NSNotification*)notification {
    // Get the list of keys that changed.
    NSLog(@"Update Called");
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    NSInteger reason = -1;
    
    // If a reason could not be determined, do not update anything.
    if (!reasonForChange)
        return;
    
    // Update only for changes from the server.
    reason = [reasonForChange integerValue];
    if ((reason == NSUbiquitousKeyValueStoreServerChange) ||
        (reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {
        // If something is changing externally, get the changes
        // and update the corresponding keys locally.
        NSArray* changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // This loop assumes you are using the same key names in both
        // the user defaults database and the iCloud key-value store
        for (NSString* key in changedKeys) {
            id value = [store objectForKey:key];
            NSLog(@"Changed Value %@",value);
            [userDefaults setObject:value forKey:key];
            
            NSString *defaultSliderValue =[NSString stringWithFormat:@"%f",[userDefaults floatForKey:@"SliderValue"]];

            self.valueLabel.text = defaultSliderValue;
            self.slider.value = [userDefaults floatForKey:@"SliderValue"];
        }
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
