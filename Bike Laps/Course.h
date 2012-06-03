//
//  Course.h
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Path.h"
#import "Workout.h"

@interface Course : Path

@property (nonatomic, strong) NSNumber*listOrder;
@property (nonatomic, strong) NSNumber*courseTimeInterval;
@property (nonatomic, strong) NSNumber*lapTimeInterval;
@property (nonatomic, strong) NSNumber*maxSavedWorkouts;
@property (nonatomic, strong) NSString*name;
@property (nonatomic, strong) NSOrderedSet *workouts;
@property (nonatomic, strong) NSNumber*bestGPS;

+(NSString*)defaultName;
-(void)addWorkout:(Workout*)workout;

@end

@interface Course (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inWorkoutsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromWorkoutsAtIndex:(NSUInteger)idx;
- (void)insertWorkouts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeWorkoutsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInWorkoutsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceWorkoutsAtIndexes:(NSIndexSet *)indexes withWorkouts:(NSArray *)values;
- (void)addWorkoutsObject:(NSManagedObject *)value;
- (void)removeWorkoutsObject:(NSManagedObject *)value;
- (void)addWorkouts:(NSOrderedSet *)values;
- (void)removeWorkouts:(NSOrderedSet *)values;

@end
