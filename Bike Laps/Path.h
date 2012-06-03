//
//  Path.h
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface Path : NSManagedObject

@property (nonatomic, strong) NSDate * timestamp;
@property (nonatomic, strong) NSOrderedSet *locations;

- (BOOL)empty;
- (int)nearestIndexFor:(Location*)location startIndex:(int)startIndex slopMeters:(double)slopMeters;
- (void)boundingBoxMinLat:(double*)minLat maxLat:(double*)maxLat minLon:(double*)minLon maxLon:(double*)maxLon;
- (double)length;
- (NSTimeInterval)time; 

@end

@interface Path (CoreDataGeneratedAccessors)

- (void)insertObject:(Location *)value inLocationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLocationsAtIndex:(NSUInteger)idx;
- (void)insertLocations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLocationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLocationsAtIndex:(NSUInteger)idx withObject:(Location *)value;
- (void)replaceLocationsAtIndexes:(NSIndexSet *)indexes withLocations:(NSArray *)values;
- (void)addLocationsObject:(Location *)value;
- (void)removeLocationsObject:(Location *)value;
- (void)addLocations:(NSOrderedSet *)values;
- (void)removeLocations:(NSOrderedSet *)values;
@end
