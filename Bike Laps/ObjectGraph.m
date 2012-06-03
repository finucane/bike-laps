//
//  ObjectGraph.m
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjectGraph.h"
#import "insist.h"

@implementation ObjectGraph

-(id)init
{
  NSError*__autoreleasing error;
  
  if (!(self = [super init]))
    return nil;
  
  /*set up core data*/
  NSURL*url = [[NSBundle mainBundle] URLForResource:@"Bike-Laps" withExtension:@"mom"];
  managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
  insist (managedObjectModel);
  
  /*
    at some point learn how to clean up old databases during development. for now just increment the name when we change
    the schema.
   */
  
  url = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Bike-Laps.sqlite"];
  persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
  [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error];
  
  managedObjectContext = [[NSManagedObjectContext alloc] init];
  insist (managedObjectContext);
  [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];

  
  /*fetch all of the existing courses from the persistent store*/
  NSFetchRequest*request = [[NSFetchRequest alloc] init];
  insist (request);
  NSSortDescriptor*sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"listOrder" ascending:YES];
  insist (sortDescriptor);
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [request setEntity:[NSEntityDescription entityForName:@"Course" inManagedObjectContext:managedObjectContext]];
  
  NSArray*array = [managedObjectContext executeFetchRequest:request error:&error];
  insist (array);
  
  courses = [NSMutableArray arrayWithArray:array];
  
  return self;    
}

/*we use ObjectGraph as a singleton class*/
+ (id)sharedInstance
{
  static dispatch_once_t onceToken = 0;
  __strong static ObjectGraph*theObjectGraph = nil;
  dispatch_once(&onceToken, ^{
                  theObjectGraph = [[self alloc] init];
                });
  return theObjectGraph;
}

- (void)save
{
  NSError*__autoreleasing error = nil;
  BOOL r;
  insist (managedObjectContext);
  
  if ([managedObjectContext hasChanges])
  {
    r =  [managedObjectContext save:&error];
    insist (r);
  }
}

-(NSArray*)getCourses
{
  return courses;
}

/*add an new course to the object graph (at the end of the list of courses)
  the course is marked as not been used yet by being given a timestamp
  in the distant past.
 */
-(Course*)addCourseWithName:(NSString*)name
{
  insist (managedObjectContext && courses);
  
  Course*course = [NSEntityDescription insertNewObjectForEntityForName:@"Course" inManagedObjectContext:managedObjectContext];
  insist (course);
  
  course.name = name;
  course.timestamp = [NSDate distantPast];
  course.listOrder = [NSNumber numberWithInt:[courses count]];                 
  [courses addObject:course];
  return course;
}

-(void) removeCourse:(Course*)course
{
  /*remove course from array and reset the list ordering*/
  [courses removeObject:course];
  for (int i = 0; i < [courses count]; i++)
  {
    Course*c = [courses objectAtIndex:i];
    c.listOrder = [NSNumber numberWithInt:i];
  } 
  
  /*remove course from object graph. we have the model set up to do the right thing about
    deleting the courses workouts and all the laps in each workout, all that stuff.*/
  [managedObjectContext deleteObject:course];
}

- (void)moveCourseFrom:(int)from to:(int)to
{
  Course*course = [courses objectAtIndex:from];
  [courses removeObjectAtIndex:from];
  [courses insertObject:course atIndex:to];
  for (int i = 0; i < [courses count]; i++)
  {
    Course*c = [courses objectAtIndex:i];
    c.listOrder = [NSNumber numberWithInt:i];
  } 
}


/*find the course that was touched most recently. this is our only app state, and it's only every
  changed in the courses table view. we just do a linear search each time.*/
- (Course*)mostRecentCourse
{
  Course*recent = nil;
  for (Course*course in courses)
  {
    if (!recent || [recent.timestamp compare:course.timestamp] == NSOrderedAscending)
      recent = course;
  }
  return recent;
}

- (Location*)addLocationWithTimestamp:(NSDate*)timestamp latitude:(double)latitude longitude:(double)longitude
{
  insist (managedObjectContext);
  
  Location*location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
  insist (location);
  
  location.timestamp = timestamp;
  location.latitude = [NSNumber numberWithDouble:latitude];
  location.longitude = [NSNumber numberWithDouble:longitude];
  return location;
}

/*general purpose methods to add and remove an object from the graph. some objects (like Course) need to be removed
  another way because of side effect.
 */
-(void)remove:(NSManagedObject*)object
{
  [managedObjectContext deleteObject:object];
}

- (NSManagedObject*)addObjectNamed:(NSString*)name
{
  insist (managedObjectContext);
  
  NSManagedObject*object = [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:managedObjectContext];
  return object;
}


/*
  clear out all of the locations in a path's "array", making sure that the locations
  are also removed from the object graph. this is so we can handle the case of an
  insufficiently short course without having to obliterate the whole course.
*/
- (void)emptyPath:(Path*)path
{
  while ([path.locations count])
  {
    Location*location = [path.locations lastObject];
    [path removeObjectFromLocationsAtIndex:[path.locations count] - 1];
    [self remove:location];
  }
}

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL*)applicationDocumentsDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
