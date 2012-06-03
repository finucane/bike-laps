//
//  LocationCollector.m
//  Laps
//
//  Created by finucane on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocationCollector.h"
#import "insist.h"
#import "ObjectGraph.h"
#import "Logger.h"

#define WORST_ACCURACY 100.0 // meters
#define WORST_TIMESTAMP_DELAY -10.0 // seconds, negative for the past

@implementation LocationCollector 

@synthesize timeInterval = timeInterval;
@synthesize running = running;
@synthesize delegate = delegate;

/*
  initially we aren't running, also we have an infinite time interval (value 0).
  to get this thing to actually start collecting location points, we need to
  have a nonzero time interval and running should be true.
 
  for simplicty, whenever timeInterval changes, we collect another sample
  immediately (if we are running). similarly, going from non running to running
  will trigger an immediate sample. this is so we can use LocationCollector to
  always get a first location point, to mark the actual start of a lap.
 
  if the caller cares about when this first point is obtained, he can register himself
  as a delegate to LocationCollector.
  
  finally, for more simplicity, the way we do our sampling is we periodically tell the location
  manager to (optionally) turn itself on. and whenever the location manager does get a new
  location we tell it to turn off. that way it's our timer that brings the location manager
  back to life (if we are "running") -- without our intervention it never gets to do more
  than 1 sample.
 
  we can always get a new sample by setting locationCollector.running to YES (even if it's
  already running).
 
*/


-(id)init
{
  if (!(self = [super init]))
    return self;
  running = NO;
  timeInterval = 0;
  delegate = nil;
  
  locationManager = [[CLLocationManager alloc] init];
  insist (locationManager);
  locationManager.delegate = self;
  locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
  timer = nil;

  return self;
}

-(void)timeout:(NSTimer*)aTimer
{
  [locationManager startUpdatingLocation];
}

/*convenience method to always do the right thing in terms of setting or clearing the timer. this also does
  the right thing in that it will trigger an immediate location update.*/
-(void)resetTimer
{
  if (timer)
  {
    [timer invalidate];
    timer = nil;
  }
  if (timeInterval == 0.0 || !running)
    return;

  [locationManager startUpdatingLocation];
   timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timeout:) userInfo:nil repeats:YES];
}

-(void)setTimeInterval:(NSTimeInterval)aTimeInterval
{
  timeInterval = aTimeInterval;
  [self resetTimer];
}
-(void)setRunning:(BOOL)isRunning
{
  running = isRunning;
  [self resetTimer];
}

-(void)setBestGPS:(BOOL)bestGPS
{
  insist (locationManager);
  locationManager.desiredAccuracy = bestGPS? kCLLocationAccuracyBest : kCLLocationAccuracyNearestTenMeters;
}

- (void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
  /*
    when the location manager starts, it sends back cached data, which is crap.
   
    "
    When requesting high-accuracy location data, the initial event delivered by the location service may not have the
    accuracy you requested. The location service delivers the initial event as quickly as possible. It then continues
    to determine the location with the accuracy you requested and delivers additional events, as necessary, when that
    data is available.
   "
   
    so ... throw out bad points. 
   
    don't be too strict about horizontal accuracy. we just have to pick a reasonable hardcoded number, we'll
    can't even remotely assume we'll get anything like what our desiredAccuracy is, at least not on my old iphone 3.
    (65 == 65m is the best it gets).
   
   in the time comparison, a negative result is in the past.
   */
  NSTimeInterval sinceNow = [newLocation.timestamp timeIntervalSinceNow];
  
  if (newLocation.horizontalAccuracy > WORST_ACCURACY || sinceNow < WORST_TIMESTAMP_DELAY)
  {
    //log (@"ignoring bad point. horizontalAccuracy is %lf, desired %lf, timeDiff is %lf", newLocation.horizontalAccuracy, locationManager.desiredAccuracy, sinceNow);
    return;
  }
      
  /*turn the location manager off. only our timer will turn it back on at some point*/
  [locationManager stopUpdatingLocation];
  
  /*if there's no delegate, we are ignoring the location*/
  if (!delegate) return;
  
  /*also if we aren't running ... this can happen because the location manager will get an initial location from the
    didChangeAuthorisationStatus method on startup. harmless if we catch it*/
  if (!running || timeInterval == 0.0)
    return;
  
  /*add a new location to the object graph. it will be up to the delegate to remove it (at some point).*/
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  insist (objectGraph);
  
  
  Location*location = [objectGraph addLocationWithTimestamp:newLocation.timestamp
                                                   latitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
  insist (location);
  
  [delegate locationCollector:self newLocation:location];
}

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusAuthorized)
    [locationManager startUpdatingLocation];
  else
    [locationManager stopUpdatingLocation];
}

/*force an update now, just to get a quick point outside of the usual sample rate*/
-(void)poke
{
  [locationManager startUpdatingLocation];
}

@end
