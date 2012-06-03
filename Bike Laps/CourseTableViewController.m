//
//  CourseTableViewController.m
//  Laps
//
//  Created by finucane on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CourseTableViewController.h"
#import "WorkoutTableViewController.h"
#import "PathMapViewController.h"
#import "Alert.h"
#import "insist.h"
#import "BikeLaps.h"

/*We have a policy of Avoiding Capitalizing Every Word Because Once You Do That You Can Never Stop*/
#define COURSE_TIME_INTERVAL_FORMAT_STRING @"Course GPS every %d %@%@"
#define LAP_TIME_INTERVAL_FORMAT_STRING @"Lap GPS every %d %@%@"
#define MAXIMUM_SAVED_WORKOUTS_FORMAT_STRING @"Save %d workout%@"
#define METERS_PER_MILE 1609.344

@implementation CourseTableViewController

@synthesize nameTextField = nameTextField;
@synthesize courseTimeIntervalSlider = courseTimeIntervalSlider;
@synthesize lapTimeIntervalSlider = lapTimeIntervalSlider;
@synthesize maxSavedWorkoutsSlider = maxSavedWorkoutsSlider;
@synthesize courseTimeIntervalLabel = courseTimeIntervalLabel;
@synthesize lapTimeIntervalLabel = lapTimeIntervalLabel;
@synthesize maxSavedWorkoutsLabel = maxSavedWorkoutsLabel;
@synthesize nameTableViewCell = nameTableViewCell;
@synthesize courseTimeIntervalTableViewCell = courseTimeIntervalCell;
@synthesize lapTimeIntervalTableViewCell = lapTimeIntervalTableViewCell;
@synthesize maxSavedWorkoutsTableViewCell = maxSavedWorkoutsTableViewCell;
@synthesize bestGPSTableViewCell = bestGPSTableViewCell;
@synthesize bestGPSSwitch = bestGPSSwitch;
 

 
- (void)updateMaxSavedWorkoutsLabel:(int)sliderValue
{
  maxSavedWorkoutsLabel.text = [NSString stringWithFormat:MAXIMUM_SAVED_WORKOUTS_FORMAT_STRING, sliderValue, sliderValue != 1 ? @"s" : @""];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil course:(Course*)aCourse
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
    course = aCourse;
    
    /*the most complicated class in iOS. do this right later*/
    dateFormatter = [[NSDateFormatter alloc] init];
    insist (dateFormatter);
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    [dateFormatter setDateFormat:@"EEE, LLL dd, YYYY"];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  nameTextField.text = course.name;
  bestGPSSwitch.on = [course.bestGPS boolValue];
  
  /*make a relevant navigation bar title. it takes 1 line to be profession like this.*/
  self.title = course.name;
  
  /*
    these 2 are nice LogarithmicSliders that I stole off the internet. We get at their values through
    a new property, sliderValue
  */
  
  courseTimeIntervalSlider.sliderValue = [course.courseTimeInterval intValue];
  lapTimeIntervalSlider.sliderValue = [course.lapTimeInterval intValue];
  maxSavedWorkoutsSlider.value = [course.maxSavedWorkouts intValue];
  
  /*
   setting slider values programatically does not trigger their value changed actions.
   we still need to set the label strings for these.
   
   just call the actions here. if we care about detecting when a course's settings
   have changed, there are better ways of doing this than involving this controller
   at all.
   
   */
  [self courseTimeIntervalChanged:courseTimeIntervalSlider];
  [self lapTimeIntervalChanged:lapTimeIntervalSlider];
  
  /*
    we can't even do this through actions because our action on this one slider is going to trigger
    a confirmation alert box. since we don't want the user to delete workouts without confirming
   */
  [self updateMaxSavedWorkoutsLabel:maxSavedWorkoutsSlider.value];
 }
 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait (interfaceOrientation);
}

#pragma mark - Table view data source

/*
  we have a section for settings and optional sections if we have measured the course yet,
  and if there are any workouts
*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  int sectionCount = 1; 
  if ([course.locations count])
    sectionCount++;
  if ([course.workouts count])
    sectionCount++;
  return sectionCount;
 
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case 0:return 5;//settings
    case 1:return 1;//one course path
    case 2:return [course.workouts count];
    default:break;
  }
  insist (0);
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  int section = [indexPath section];
  int row = [indexPath row];
 
  if (section == 0)
  {
    /*these are already loaded from the xib, and their values are always up to date. so just return them*/
    switch (row)
    {
      case 0:return nameTableViewCell;
      case 1:return courseTimeIntervalCell;
      case 2:return lapTimeIntervalTableViewCell;
      case 3:return maxSavedWorkoutsTableViewCell;
      case 4:return bestGPSTableViewCell;
      default:
        insist (0);
        break;
    }
  }
    
  /*
    we make sure we only show discloure buttons if there's something to disclose. either a nonzero
    course path, or workouts with laps
   */
  if (section == 1)
  {
    static NSString *CellIdentifier = @"pathCell";
    UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    insist (cell);

    /*this should never be zero, but we don't count on that here*/
    int numLocations = [course.locations count];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d point%@)",
                           [dateFormatter stringFromDate:course.timestamp], numLocations, numLocations != 1 ? @"s" : @""];
    double meters = [course length];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f miles (%.2f km)", meters / METERS_PER_MILE, meters / 1000.0];
    cell.accessoryType = numLocations ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
    return cell;
  }
  else
  {
    static NSString *CellIdentifier = @"workoutCell";
    UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    insist (cell);

    insist (row >= 0 && row < [course.workouts count]);
    Workout*workout = [course.workouts objectAtIndex:row];
    int numLaps = [workout.laps count];
    insist (numLaps > 0);
    Lap*lap = [workout.laps objectAtIndex:0];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d Lap%@)", 
                           [dateFormatter stringFromDate:lap.timestamp],
                           numLaps, numLaps != 1 ? @"s" : @""];
    
    /*compute the total workout time as the sum of all of the lap splits*/
    unsigned seconds = 0;
    for (int i = 0; i < [workout.laps count]; i++)
      seconds += [workout splitForLap:i];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:SECONDS_FMT, SECONDS_ARGS (seconds)];

    cell.accessoryType = numLaps ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
    return cell;
  }
  insist (0);
  return nil;
}
 
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case 0: return @"Settings";
    case 1: return @"Path";
    case 2: return @"Workouts";
    default:break;
  }
  insist (0);
  return nil;
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  int row = [indexPath row];
  int section = [indexPath section];
  
  if (section == 1)
  {
    insist (row == 0);
    PathMapViewController*controller = [[PathMapViewController alloc] initWithNibName:@"PathMapViewController" bundle:nil title:course.name Path:course];
    insist (controller);
    [self.navigationController pushViewController:controller animated:YES];
  }
  else
  {
    insist (section == 2);
    insist (row >= 0 && row < [course.workouts count]);
    WorkoutTableViewController*controller = [[WorkoutTableViewController alloc] initWithNibName:@"WorkoutTableViewController" bundle:nil workout:[course.workouts objectAtIndex:row]];
    insist (controller);
    [self.navigationController pushViewController:controller animated:YES];
  }
}

/*
 these 3 textFieldDelegate methods validate the name field, making sure that the user never enters
 the empty string.
 */
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
  NSString*name = [nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  return [name length] != 0;
}

/*we will still have a chance to cancel this, if the name field is empty, in textFieldShouldEndEditing*/
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}

/*
 if for some reason the user gets past the validation, above, we still prevent him from naming
 a course nothing. just be sure.
 
 also we make sure the navigation controller back button is disabled (by hiding it) when we
 have the keyboard up. this avoids confusion and also it avoids some weirdness where if you pop a view
 controller and resignFirstResponder hasn't been called (keyboard was still up when its view slid off),
 it won't ever come back. even in a new view controller.
*/
- (void)textFieldDidEndEditing:(UITextField *)textField
{
  NSString*name = [nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([name length] == 0)
    name = [Course defaultName];
  course.name = name;
  
  /*be nice. update the navigation bar title.*/
  self.title = course.name;
  
  self.navigationItem.hidesBackButton = NO;
  
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  self.navigationItem.hidesBackButton = YES;
}

/*
 these actions wired to the sliders keep the labels up to date, and they also update the course values.
 our philosphy in this view controller is to always keep the course updated, so we never have to worry
 about when the view controller actually goes away, like to do one "save changes" call. this is simple.
 
 there is a downside, for intance we don't have any notion of cancel. but for a 3 screen app this is
 not horrible, the main thing is to show the user a consistent behavior.
 */
 
-(IBAction)courseTimeIntervalChanged:(id)sender
{
  int sliderValue = (int)courseTimeIntervalSlider.sliderValue;//LogarithmicSlider
  course.courseTimeInterval = [NSNumber numberWithInt:sliderValue];
  
  NSString*units = @"second";
  if (sliderValue >= 60)
  {
    sliderValue /= 60;
    units = @"minute";
  }
  
  courseTimeIntervalLabel.text = [NSString stringWithFormat:COURSE_TIME_INTERVAL_FORMAT_STRING, sliderValue, units, sliderValue != 1 ? @"s" : @""];
  
}
-(IBAction)lapTimeIntervalChanged:(id)sender
{
  insist (lapTimeIntervalSlider && sender == lapTimeIntervalSlider);

  int sliderValue = (int)lapTimeIntervalSlider.sliderValue;//LogarithmicSlider
  course.lapTimeInterval = [NSNumber numberWithInt:sliderValue];
  
  NSString*units = @"second";
  if (sliderValue >= 60)
  {
    sliderValue /= 60;
    units = @"minute";
  }
  lapTimeIntervalLabel.text = [NSString stringWithFormat:LAP_TIME_INTERVAL_FORMAT_STRING, sliderValue, units, sliderValue != 1 ? @"s" : @""];
}

/* 
 the max workouts slider is set to not contiguious just to make it easier to do the confirmation alert. this is pretty bad, the right
 way to do this is with a timer or even subclassing the control and trapping the finger up event.
 
 to do later basically. the reason this is bad, anyway, is the user's not going to get any feedback of what he's changing
 the value to, until he lets go. he will have a chance to cancel though. 
*/

-(IBAction)maxSavedWorkoutsChanged:(id)sender
{
  insist (maxSavedWorkoutsSlider && sender == maxSavedWorkoutsSlider);
  
  int sliderValue = (int)[maxSavedWorkoutsSlider value];
  
  int numDeletedWorkouts = [course.workouts count] - sliderValue;
  if (numDeletedWorkouts > 0)
  {
    /*apple hates the idea of pretending we have files on the phone, so we are removing, not deleting*/
    BOOL ok = [[Alert sharedInstance]
               alertWithTitle:@"Removing Workouts"
                      message:[NSString stringWithFormat:@"This will remove your oldest %d workout%@. Are you sure?",
                        numDeletedWorkouts, numDeletedWorkouts == 1 ? @"" : @"s"]
               showCancel:YES];
    
    /*if the user said no, restore the slider value and get out of this method*/
    if (!ok)
    {
      maxSavedWorkoutsSlider.value = [course.maxSavedWorkouts intValue];
      [self updateMaxSavedWorkoutsLabel:maxSavedWorkoutsSlider.value];
      return;
    }
    else
    {
      /*
        actually free up the removed workouts here. this is not terribly efficient,
        but it's because core data isn't generating our nice access methods for
        NSOrderedSet, so we are writing them on demand, and being lazy.
      */
      for (int i = 0; i < numDeletedWorkouts; i++)
      {
        [[ObjectGraph sharedInstance] remove:[course.workouts objectAtIndex:0]];
        [course removeObjectFromWorkoutsAtIndex:0];
      }

      [self.tableView reloadData];
    }
  }
  
  course.maxSavedWorkouts = [NSNumber numberWithInt:sliderValue];
  [self updateMaxSavedWorkoutsLabel:maxSavedWorkoutsSlider.value];
}

-(IBAction)bestGPSSwitchChanged:(id)sender
{
  insist (course && bestGPSSwitch);
  insist (sender == bestGPSSwitch);
  
  course.bestGPS = [NSNumber numberWithBool:bestGPSSwitch.on];
} 

-(void)viewWillAppear:(BOOL)animated
{
  self.navigationController.navigationBarHidden = NO;
  self.navigationController.toolbarHidden = YES;
  [super viewWillAppear:animated];
}

@end
