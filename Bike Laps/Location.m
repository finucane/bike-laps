//
//  Location.m
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "Location.h"
#import "Path.h"


@implementation Location

@dynamic latitude;
@dynamic longitude;
@dynamic timestamp;
@dynamic path;

/*in meters*/
-(double)distance:(Location*)location
{
  CLLocation*me = [[CLLocation alloc]initWithLatitude:[self.latitude doubleValue] longitude:[self.longitude doubleValue]];
  CLLocation*him = [[CLLocation alloc] initWithLatitude:[location.latitude doubleValue] longitude:[location.longitude doubleValue]];
  return [me distanceFromLocation:him];
}

@end
