//
//  WorkoutTableViewController.h
//  Laps
//
//  Created by finucane on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Workout.h"

@interface WorkoutTableViewController : UITableViewController
{
  @private
  Workout*workout;
  NSDateFormatter*dateFormatter;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil workout:(Workout*)aWorkout;
@end
