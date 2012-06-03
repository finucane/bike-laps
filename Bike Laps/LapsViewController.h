//
//  LapsViewController.h
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Course.h"
#import "LocationCollector.h"

@class ObjectGraph;

/*
  this basically the main view controller which does most of the actual app
  features.
 
  it responds to all of the measure/pause/resume start/stop lap controls,
  the music buttons, and takes all the GPS measurements and updates the
  workout state and displays the lap count and elapsed time.
*/

@interface LapsViewController : UIViewController <LocationCollectorDelegate>
{
  @private
  MPMusicPlayerController*musicPlayer;
  UIBarButtonItem*rewindButton,*pauseButton,*playButton,*fastForwardButton;
  NSDate*startDate;
  Course*currentCourse;
  LocationCollector*locationCollector;
  NSTimer*timer;
  BOOL locked;
  /*
    these are to correct for the part of elasped time that shouldn't count -- when the user was
    pausing. pauseSeconds is the total count of time spent pausing during a workout. the timestamp
    is whenever a pause period started.
   */
  NSDate*pauseTimestamp;
  NSTimeInterval pauseSeconds;
  NSTimeInterval splitPauseSeconds;
  
  /*this will be either the course we are measuring, or the new lap we are on*/
  Path*currentPath;
  int lastIndex; //to keep track of how far we are going around tracking the course path
}

@property (nonatomic, weak) IBOutlet UIButton*startLapsButton;
@property (nonatomic, weak) IBOutlet UIButton*measureCourseButton;
@property (nonatomic, weak) IBOutlet UIButton*stopButton;
@property (nonatomic, weak) IBOutlet UIButton*pauseCourseButton;
@property (nonatomic, weak) IBOutlet UIButton*resumeCourseButton;
@property (nonatomic, weak) IBOutlet UIButton*infoButton;
@property (nonatomic, weak) IBOutlet UILabel*nameLabel;
@property (nonatomic, weak) IBOutlet UILabel*lapCountLabel;
@property (nonatomic, weak) IBOutlet UILabel*timeLabel;
@property (nonatomic, weak) IBOutlet UILabel*splitLabel;
@property (nonatomic, weak) IBOutlet UIView*buttonsView;
@property (nonatomic, weak) IBOutlet UITextView*splitsTextView;
@property (nonatomic, weak) IBOutlet UISlider*lockSlider;

-(void)setToolbarItemsAnimated:(BOOL)animated;
-(void)reset;
-(IBAction)info:(id)sender;
-(IBAction)startLaps:(id)sender;
-(IBAction)measureCourse:(id)sender;
-(IBAction)pauseCourse:(id)sender;
-(IBAction)resumeCourse:(id)sender;
-(IBAction)stop:(id)sender;
 
-(IBAction)play:(id)sender;
-(IBAction)pause:(id)sender;
-(IBAction)fastForward:(id)sender;
-(IBAction)rewind:(id)sender;
-(IBAction)toggleLock:(id)sender;

@end
