//
//  PathMapViewController.m
//  Laps
//
//  Created by finucane on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PathMapViewController.h"
#import "Location.h"
#import "insist.h"

@implementation PathMapViewController
@synthesize mapView = mapView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title Path:(Path*)aPath
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
      path = aPath;
      self.navigationItem.title = title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{  
  insist ([path.locations count]);
  
  self.navigationController.navigationBarHidden = NO;
  self.navigationController.toolbarHidden = YES;
  [super viewWillAppear:animated];
  
  for (int i = 0; i < [path.locations count]; i++)
  {
    CLLocationCoordinate2D point;

    Location*location = [path.locations objectAtIndex:i];
    point.latitude = [location.latitude doubleValue];
    point.longitude = [location.longitude doubleValue];
    
    MKPointAnnotation*annotation = [[MKPointAnnotation alloc]init];
    insist (annotation);
    annotation.coordinate = point;
    annotation.title = [NSString stringWithFormat:@"%d", i];
    [mapView addAnnotation:annotation];
  }
  
  CLLocationCoordinate2D min, max, center;

  [path boundingBoxMinLat:&min.latitude maxLat:&max.latitude minLon:&min.longitude maxLon:&max.longitude];

  /*for the math done in meters*/
  CLLocation*topLeft = [[CLLocation alloc]initWithLatitude:min.latitude longitude:min.longitude];
  CLLocation*topRight = [[CLLocation alloc]initWithLatitude:min.latitude longitude:max.longitude];
  CLLocation*bottomLeft = [[CLLocation alloc]initWithLatitude:max.latitude longitude:min.longitude];

  CLLocationDistance latDistance = [bottomLeft distanceFromLocation:topLeft];
  CLLocationDistance lonDistance = [topRight distanceFromLocation:topLeft];
  
  /*math done in degrees*/
  center.latitude = min.latitude + (max.latitude - min.latitude) / 2.0;
  center.longitude = min.longitude + (max.longitude - min.longitude) / 2.0;

  MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(center, latDistance, lonDistance);
  
  MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];                
  [mapView setRegion:adjustedRegion animated:YES];        
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
  
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return UIInterfaceOrientationIsPortrait (interfaceOrientation);
}

- (void) dealloc
{
  /*
    "Before releasing an MKMapView object for which you have set a delegate, remember to set that
    object’s delegate property to nil. One place you can do this is in the dealloc
    method where you dispose of the map view."
   */
  mapView.delegate = nil;
}
@end
