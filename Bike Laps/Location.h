//
//  Location.h
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Path;

@interface Location : NSManagedObject

@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSDate * timestamp;
@property (nonatomic, strong) Path *path;

-(double)distance:(Location*)location;
@end
