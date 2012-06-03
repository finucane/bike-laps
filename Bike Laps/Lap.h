//
//  Lap.h
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Path.h"


@interface Lap : Path

@property (nonatomic, strong) NSManagedObject *workout;
@end
