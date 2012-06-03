//
//  PathMapViewController.h
//  Laps
//
//  Created by finucane on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Path.h"

@interface PathMapViewController : UIViewController <MKMapViewDelegate>
{
  @private
  Path*path;
}
@property (nonatomic, weak) IBOutlet MKMapView*mapView;
- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil title:(NSString*)title Path:(Path*)aPath;

@end
