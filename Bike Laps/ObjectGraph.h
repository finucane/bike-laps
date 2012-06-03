//
//  ObjectGraph.h
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Course.h"
#import "Path.h"
#import "Location.h"
#import "Lap.h"
#import "Workout.h"

@interface ObjectGraph : NSObject
{
  @private
  NSManagedObjectContext*managedObjectContext;
  NSManagedObjectModel*managedObjectModel;
  NSPersistentStoreCoordinator*persistentStoreCoordinator;
  NSMutableArray*courses;
}

@property (nonatomic, readonly, getter=getCourses) NSArray*courses;

- (void)save;
- (Course*)mostRecentCourse;
- (Course*)addCourseWithName:(NSString*)name;
- (Location*)addLocationWithTimestamp:(NSDate*)timestamp latitude:(double)latitude longitude:(double)longitude;
- (void)removeCourse:(Course*)course;
- (void)moveCourseFrom:(int)from to:(int)to;
+ (id)sharedInstance;
- (void)remove:(NSManagedObject*)object;
- (NSManagedObject*)addObjectNamed:(NSString*)name;
- (void)emptyPath:(Path*)path;

@end
