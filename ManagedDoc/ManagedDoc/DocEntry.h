//
//  DocEntry.h
//  ManagedDoc
//
//  Created by Studio on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DocEntry : NSManagedObject

@property (nonatomic, retain) NSString * docText;
@property (nonatomic, retain) NSString * docTitle;
@property (nonatomic, retain) NSDate * syncDate;

@end
