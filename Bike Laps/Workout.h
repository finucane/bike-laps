//
//  Workout.h
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Course, Lap;

@interface Workout : NSManagedObject
{
  
}

@property (nonatomic, strong) Course *course;
@property (nonatomic, strong) NSOrderedSet *laps;
-(NSTimeInterval)splitForLap:(int)lapIndex;

@end

@interface Workout (CoreDataGeneratedAccessors)

- (void)insertObject:(Lap *)value inLapsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLapsAtIndex:(NSUInteger)idx;
- (void)insertLaps:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLapsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLapsAtIndex:(NSUInteger)idx withObject:(Lap *)value;
- (void)replaceLapsAtIndexes:(NSIndexSet *)indexes withLaps:(NSArray *)values;
- (void)addLapsObject:(Lap *)value;
- (void)removeLapsObject:(Lap *)value;
- (void)addLaps:(NSOrderedSet *)values;
- (void)removeLaps:(NSOrderedSet *)values;

@end
