//
//  MFDummy.h
//  MagicalFreeze
//
//  Created by xissburg on 7/27/13.
//  Copyright (c) 2013 xissburg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MFDummy : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * dummyId;

@end
