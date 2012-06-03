//
//  CourseTableViewController.h
//  Laps
//
//  Created by finucane on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LogarithmicSlider.h"
#import "ObjectGraph.h"

@interface CourseTableViewController : UITableViewController <UITextFieldDelegate>
{
  @private
  Course*course;
  NSDateFormatter*dateFormatter;
}

/*since these are not really attached to any views when we load, make them strong references*/
@property (nonatomic, strong) IBOutlet UITableViewCell*nameTableViewCell;
@property (nonatomic, strong) IBOutlet UITableViewCell*courseTimeIntervalTableViewCell;
@property (nonatomic, strong) IBOutlet UITableViewCell*lapTimeIntervalTableViewCell;
@property (nonatomic, strong) IBOutlet UITableViewCell*maxSavedWorkoutsTableViewCell;
@property (nonatomic, strong) IBOutlet UITableViewCell*bestGPSTableViewCell;

@property (nonatomic, weak) IBOutlet UITextField*nameTextField;
@property (nonatomic, weak) IBOutlet LogarithmicSlider*courseTimeIntervalSlider;
@property (nonatomic, weak) IBOutlet LogarithmicSlider*lapTimeIntervalSlider;
@property (nonatomic, weak) IBOutlet UISlider*maxSavedWorkoutsSlider;
@property (nonatomic, weak) IBOutlet UILabel*courseTimeIntervalLabel;
@property (nonatomic, weak) IBOutlet UILabel*lapTimeIntervalLabel;
@property (nonatomic, weak) IBOutlet UILabel*maxSavedWorkoutsLabel;
@property (nonatomic, weak) IBOutlet UISwitch*bestGPSSwitch;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil course:(Course*)aCourse;
-(IBAction)courseTimeIntervalChanged:(id)sender;
-(IBAction)lapTimeIntervalChanged:(id)sender;
-(IBAction)maxSavedWorkoutsChanged:(id)sender;
-(IBAction)bestGPSSwitchChanged:(id)sender;


@end
