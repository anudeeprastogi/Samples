//
//  MyDocuments.h
//  DocManager
//
//  Created by Studio on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MyDocuments : NSManagedObject

@property (nonatomic, retain) NSData * myImage;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * docIndex;

@end
