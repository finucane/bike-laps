//
//  LocationCollector.h
//  Laps
//
//  Created by finucane on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Location.h"

@class LocationCollector;
@protocol LocationCollectorDelegate <NSObject>

-(void)locationCollector:(LocationCollector*)locationCollector newLocation:(Location*)location;

@end

@interface LocationCollector : NSObject <CLLocationManagerDelegate>
{
  @private
  CLLocationManager*locationManager;
  NSTimer*timer;
}

@property (nonatomic, weak) id<LocationCollectorDelegate> delegate;
@property (nonatomic, setter=setTimeInterval:) NSTimeInterval timeInterval;
@property (nonatomic, setter=setRunning:) BOOL running;

-(void)setBestGPS:(BOOL)bestGPS;
-(void)poke;

@end
