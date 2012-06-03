//
//  WorkoutTableViewController.m
//  Laps
//
//  Created by finucane on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WorkoutTableViewController.h"
#import "PathMapViewController.h"
#import "Lap.h"
#import "insist.h"
#import "BikeLaps.h"

@implementation WorkoutTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil workout:(Workout*)aWorkout
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
    workout = aWorkout;
 
    /*the most complicated class in iOS. do this right later*/
    dateFormatter = [[NSDateFormatter alloc] init];
    insist (dateFormatter);
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    [dateFormatter setDateFormat:@"EEE, LLL dd YYYY"];
  }
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait (interfaceOrientation);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [workout.laps count];
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  
  /*make the navigation title nice and relevant*/
  Lap*lap = [workout.laps objectAtIndex:0];
  insist (lap);
  self.title = [NSString stringWithFormat:@"%@",
                [dateFormatter stringFromDate:lap.timestamp]];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  int row = [indexPath row];
  insist (row >= 0 && row < [workout.laps count]);
          
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   
  if (!cell)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  insist (cell);
  Lap*lap = [workout.laps objectAtIndex:row];
  insist (lap);
  
  int numLocations = [lap.locations count];
  cell.textLabel.text = [NSString stringWithFormat:@"Lap %d (%d point%@)",
                          row + 1, numLocations, numLocations != 1 ? @"s" : @""];
  unsigned seconds = [workout splitForLap:row];
  cell.detailTextLabel.text = [NSString stringWithFormat:SECONDS_FMT, SECONDS_ARGS(seconds)];

  /*only make the cell disclose a map if there are locations to map*/
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.accessoryType = numLocations ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
     
  return cell;
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  int row = [indexPath row];
   
  insist (row >= 0 && row < [workout.laps count]);
  Lap*lap = [workout.laps objectAtIndex:row];
  insist (lap);
  
  PathMapViewController*controller = [[PathMapViewController alloc] initWithNibName:@"PathMapViewController" bundle:nil title:[NSString stringWithFormat:@"Lap %d", row + 1] Path:lap];
  insist (controller);
  [self.navigationController pushViewController:controller animated:YES];
}


@end
