//
//  LapsViewController.m
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LapsViewController.h"
#import "CoursesTableViewController.h"
#import "ObjectGraph.h"
#import "Alert.h"
#import "Logger.h"
#import "insist.h"
#import "BikeLaps.h"

#import <objc/runtime.h>

#define MIN_COURSE_LOCATIONS 3
#define GPS_SLOP_METERS 65 //really, on the iphone 3 at least. the algorithm shouldn't care

@implementation LapsViewController

@synthesize measureCourseButton = measureCourseButton;
@synthesize startLapsButton = startLapsButton;
@synthesize pauseCourseButton = pauseCourseButton;
@synthesize resumeCourseButton = resumeCourseButton;
@synthesize stopButton = stopButton;
@synthesize infoButton = infoButton;
@synthesize nameLabel = nameLabel;
@synthesize lapCountLabel = lapCountLabel;
@synthesize timeLabel = timeLabel;
@synthesize splitLabel = splitLabel;
@synthesize buttonsView = buttonsView;
@synthesize splitsTextView = splitsTextView;
@synthesize lockSlider = lockSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
    /*
      make the music controller buttons. one reason to do this in code, is so we can access
      them without having to wait for viewDidLoad.
     */
    
    rewindButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(rewind:)];
    playButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play:)];
    pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pause:)];
    fastForwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(fastForward:)];
    
    /*get the ipod music player and keep it around.*/
    musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    insist (musicPlayer);
    
    /*pay attention to when the player state changes, so we can update the controll icons*/      
    NSNotificationCenter*notificationCenter = [NSNotificationCenter defaultCenter];
    insist (notificationCenter);
    [notificationCenter addObserver:self selector:@selector(musicPlayerStateDidChange:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:musicPlayer];
    [musicPlayer beginGeneratingPlaybackNotifications];
    
    /*this will get set the first time when the view is loaded*/
    currentCourse = nil;
    
    /*get a location collector that we'll use to get our location data points*/
    locationCollector = [[LocationCollector alloc] init];
    insist (locationCollector);
    
    /*we care about the locations the collector collects*/
    locationCollector.delegate = self;
    
    timer = nil;
  }
  return self;
}

/*
  set the toolbar items for this view (which is intended to be inside a navigation controller depending on
  the ipod app state. you cannot modify a barbuttonitem's style once it's created, so
  we just reset the entire toobar.
 */
-(void) setToolbarItemsAnimated:(BOOL)animated
{
  UIBarButtonItem *space1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *space2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *space3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *space4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

  insist (musicPlayer);
  if (musicPlayer.playbackState == MPMusicPlaybackStatePlaying)
    [self setToolbarItems: [NSArray arrayWithObjects:space3, rewindButton, space1, pauseButton, space2, fastForwardButton, space4, nil] animated:NO];
  else
    [self setToolbarItems:[NSArray arrayWithObjects:space3, rewindButton, space1, playButton, space2, fastForwardButton, space4, nil] animated:NO];
  
 /*if we went off the end of an album or playlist nothing we can do will get music to start again,
    the user has to use the ipod app to do this. so reflect the state of our own buttons being useful or not
    by hiding or showing the entire toolbar*/
  if (musicPlayer.nowPlayingItem == nil || locked)
    [self.navigationController setToolbarHidden:YES animated:animated];
  else
    [self.navigationController setToolbarHidden:NO animated:animated];
}


/*
  put the laps controller in a sane state, based on whatever the current course is.
  if there are no courses at all, make one that the user can use and rename later.
 
  this sets currentCourse.
*/

-(void)reset
{
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  Course*course = [objectGraph mostRecentCourse];
  if (!course)
    course = [objectGraph addCourseWithName:[Course defaultName]];
  insist (course);
  self.nameLabel.text = course.name;

  self.pauseCourseButton.hidden = YES;
  self.resumeCourseButton.hidden = YES;
  self.stopButton.hidden = YES;
  
  /*if the course doesn't have a path set, make the go button say that*/
  if ([course empty])
  {
    self.startLapsButton.hidden = YES;
    self.measureCourseButton.hidden = NO;
  }
  else
  {
    self.startLapsButton.hidden = NO;
    self.measureCourseButton.hidden = YES;
  }
 
  self.timeLabel.text = nil;
  self.splitLabel.text = nil;
  self.lapCountLabel.text = nil;
  self.splitsTextView.text = nil;
  [self hideTime];
  
  /*
    we remember what course we are working on so we can respond
    to it being changed out from underneath us by the courses tableview etc.
   */
  currentCourse = course;
}
 
/*this is called whenever the music player state changes. update the toolbar items accordingly*/
-(void)musicPlayerStateDidChange:(id)notification
{
  [self setToolbarItemsAnimated:YES];
}

/*
  actions for the toolbar items to control the music player. when these cause the player to change its state,
  the player will notify us and we'll update the toolbar accordingly (showing just one of play/pause.
*/

-(IBAction)play:(id)sender
{
  insist (musicPlayer);
  [musicPlayer play];
}
-(IBAction)pause:(id)sender
{
  insist (musicPlayer);
  [musicPlayer pause];
}
-(IBAction)fastForward:(id)sender
{
  insist (musicPlayer);
  [musicPlayer skipToNextItem];
  
}
-(IBAction)rewind:(id)sender
{
  insist (musicPlayer);
  [musicPlayer skipToPreviousItem];
}

- (NSTimeInterval) getElapsedSplitTime
{
  insist (currentPath);
  NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:currentPath.timestamp];
  /*correct for pause time*/
  if (seconds > splitPauseSeconds)
    seconds -= splitPauseSeconds; 
  return seconds;
}

/*some methods to deal with the elapsed time display*/
-(void)setTime
{
  unsigned seconds = 0;

  NSDate*now = [NSDate date];
  if (currentCourse)
    seconds = (unsigned)[now timeIntervalSinceDate:currentCourse.timestamp];
  
  /*correct for pause time*/
  if (seconds > pauseSeconds)
    seconds -= pauseSeconds; 
  
  timeLabel.text = [NSString stringWithFormat:SECONDS_FMT, SECONDS_ARGS(seconds)];
  
  /*set the split label*/
  if (currentPath)
  {
    seconds = (unsigned) [self getElapsedSplitTime];
    splitLabel.text = [NSString stringWithFormat:SECONDS_FMT, SECONDS_ARGS(seconds)];
  }
}

/*update the list of splits for this workout*/
-(void)setSplitsText
{ 
  insist (splitsTextView);
  NSMutableString*s = [[NSMutableString alloc] init];
  
  /*if we are doing laps now ...*/
  if (currentPath && currentPath != currentCourse)
  {
    /*get the workout we are doing now*/
    Workout*workout = [currentCourse.workouts lastObject];

    /*
      get the split for each lap not including the lap we are on now,
      and build a string with it.
    */
    for (int i = 0; i < [workout.laps count] - 1; i++)
    {
      unsigned seconds = [workout splitForLap:i];
      [s appendFormat: [NSString stringWithFormat:@"%02u. " SECONDS_FMT "\n", i + 1, SECONDS_ARGS (seconds)]];
    }
  }
  splitsTextView.text = s;
  [splitsTextView scrollRangeToVisible:NSMakeRange([s length] -  1, 1)];

}

-(void)timeout:(NSTimer*)aTimer
{
  [self setTime];
}
-(void)startTime
{
  if (timer)
  {
    [timer invalidate];
    timer = nil;
  }
  timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeout:) userInfo:nil repeats:YES];
}
-(void)stopTime
{
  if (timer)
  {
    [timer invalidate];
    timer = nil;
  }
}
-(void)showTime
{
  [self setTime];
  timeLabel.hidden = NO;
  
  /*if we are doing laps, make the splits time visible*/
  if (currentPath != currentCourse)
    splitLabel.hidden = NO;
}

-(void)hideTime
{
  timeLabel.hidden = YES;
  splitLabel.hidden = YES;
}

/*
  when the info button is touched, we just push the courses table view controller onto
  the navigation stack. we don't need to keep any references to the controller
 */
-(IBAction)info:(id)sender
{
  CoursesTableViewController*controller = [[CoursesTableViewController alloc] initWithNibName:@"CoursesTableViewController" bundle:nil];
  insist (controller);
  [self.navigationController pushViewController:controller animated:YES];
  self.navigationController.navigationBarHidden = NO;
}


/*
 the way this all works is : if the course doesn't have a path yet,
 then when we are going, we are adding points to the path. when we
 stop, we look at the points, and if there are enough of them,
 we set the path and move the application flow to the normal case,
 which is counting laps.
 
 here we only display elapsed time.
 
 if we already have a path (which can never be changed, the only way
 to change a path is to delete the course and make a new one), then
 when we are going, we are measuring locations, displaying the lap count
 and elapsed time.
 
 each time we notice the lap count crossing an integer boundary, save all
 the locations into a new lap, and save the lap and reset the location
 collector.
 
 stop will save all the laps into a new workout and reset the state of the controller.
 
 we are using core data, so all of our app state objects are managed. we let core data
 do some of the memory management for us with some "cascade" delete rules. we are treating
 ordered to-many relationships like arrays where the array owns its elements. so for them,
 we set a cascade rule.
 
 a course and a lap are both instances of the path entity. paths have an array of locations.
 so when we delete a course or a lap, all of their locations are freed for us.
 
 a workout has an array of laps. so when we delete a workout, all the laps get deleted, and so
 all of the lap locations too.
 
 finally, a course has an array of workouts (the most recent workouts, up to some history).
 when we delete a course, all of its workouts are deleted.
 
*/

-(void)setLapCount
{
  /*get the current workout so we can get the number of laps so far*/
  insist (currentCourse);
  Workout*workout = [currentCourse.workouts lastObject];
  insist (workout);
  
  double lapCount = [workout.laps count];
  
  /*we always have at least one lap, what we are currently working on, and we do count
    actual work done ...*/
  insist (lapCount);
  lapCount--;
  
  /*if our lastIndex is in a valid range, it means we haven't started into a new lap yet, so we get
    a fractional part too*/
  
  if (lastIndex >= 0 && lastIndex < [currentCourse.locations count])
  {
    /*defeat printf's rounding! fight the power! we never want the user to see
      a X.0 figure on the display unless we really have done X number of laps.
      this is mainly so that lap splits work.
     */
    
    double fraction = (double)lastIndex / (double) [currentCourse.locations count];
    if (fraction > 0.9)
      fraction = 0.9;
    
    lapCount += fraction;
  }
  lapCountLabel.text = [NSString stringWithFormat:@"%.1f", lapCount];
}


/*
 create and add to the object graph a location corresponding to
 the start of the course we are on, and the present time.
 
 this thing should only be used on valid courses, i.e. nonempty ones.
 */

-(Location*)newLocationForCurrentCourseStartAndNow
{
  insist (currentCourse && ![currentCourse empty]);
  
  Location*courseStart = [currentCourse.locations objectAtIndex:0];
  Location*location = [[ObjectGraph sharedInstance] addLocationWithTimestamp:[NSDate date]
                                                                    latitude:[courseStart.latitude doubleValue]
                                                                   longitude:[courseStart.longitude doubleValue]];
  return location;
}

-(void)newLapAtLocation:(Location*)location
{
  insist (currentCourse);
  insist (location);
  
  Workout*workout = [currentCourse.workouts lastObject];
  insist (workout);
  
  /*add a new lap to the workout current*/
  Lap*lap = (Lap*)[[ObjectGraph sharedInstance] addObjectNamed:@"Lap"];
  insist (lap);
  [workout insertObject:lap inLapsAtIndex:[workout.laps count]];
  lap.timestamp = [NSDate date];
  
  log (@"newLapAtLocation, [workout.laps count] is now %d", [workout.laps count]);

  /*we haven't reached any course path location this time around*/
  lastIndex = -1;
  currentPath = lap;
  splitPauseSeconds = 0;
  
  
  [lap insertObject:location inLocationsAtIndex:0];
  
  [self setSplitsText];
}

-(void)locationCollector:(LocationCollector*)aLocationCollector newLocation:(Location*)location
{
  insist (location && locationCollector && aLocationCollector == locationCollector);
  insist (currentPath);
  log(@"new location %@ (%@, %@)", location.timestamp, location.latitude, location.longitude);
  
  Workout*workout = [currentCourse.workouts lastObject];
  if (workout)
  {
    log(@"[workouts.laps count] is %d", [workout.laps count]);
  }
  /*if we are measuring a course just add the point to the path*/
  if (currentPath == currentCourse)
  {
    [currentPath insertObject:location inLocationsAtIndex:[currentPath.locations count]];
    insist ([currentPath.locations lastObject] == location);
    return;
  }

  /*otherwise figure out if we are still in the current lap. this is the heart of the app*/

  int numCourseLocations = [currentCourse.locations count];
  
  /*
    find the index of the closest location in the course to where we are now, making sure to
    not to match backwards on the path. we can find the same index as we did previously, this
    would mean we are stopping or going really slow and in our sample time we didn't progress
    to the next course point. we gradually want to be increasing the index, as we make our
    way around the lap. this method also prefers matches sooner in the path rather than further,
    within a margin of error distance-wise, because GPS is not that accurate.
   */
  
  int index = [currentCourse nearestIndexFor:location startIndex:lastIndex >= 0 ? lastIndex : 0 slopMeters:GPS_SLOP_METERS];
  
  log(@"currentCourse.locations count is %d, index is %d", numCourseLocations, index);
  
  /*
    throw out any points near the start/finish line that are in the end of the lap instead of
    the beginning when they shouldn't be. this is to deal with GPS inaccuracy messing with us
    right at the start/finish area.
   
    we just sort of arbitrarily throw out points in the last 1/4 of the lap unless they occur
    after the first 1/4 in time that the lap should be taking us to do total.
   
    these numbers can be made reasonable if they aren't out of the box, by the user messing
    with the lap sample rate. none of this is very satisfactory, but if we have to do a kludge,
    we at least keep it simple.
   */
  
  if (index > numCourseLocations * 3/4)
  {
    /*get how long it took to measure the course.*/
    NSTimeInterval courseTime = [currentCourse time];
    
    /*get how far along we are in the current lap*/
    NSTimeInterval elapsed = [self getElapsedSplitTime];
    
    if (elapsed < courseTime / 4.0)
    {
      /*that sample didn't work for us. try again a little further on. this is all sort of the 
        inverse of poking to get more accurate reading when we are nearing the end of a lap,
        here we are presumably just starting out a lap and got samples bad enough that
        they came back as being on the behind-us side of the start/finish line
       */
      log (@"throwing out point, elapsed time is %lf, courseTime is %lf", elapsed, courseTime);
      
      /*
        the location passed into us from locationCollector is a core data object. if we aren't using
        it, we have to remove it from the graph
       */
      
      [[ObjectGraph sharedInstance] remove:location];
      
      dispatch_after (dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC),
                      dispatch_get_current_queue(),
                      ^{
                        log (@"poke");
                        [locationCollector poke];
                      });
      return;
    }
  }
  
  /*we are going to keep the point*/
  
  [currentPath insertObject:location inLocationsAtIndex:[currentPath.locations count]];

  if (lastIndex == numCourseLocations - 1)
  {
    /*and we are at the end of the path.
     this means we have run out of matches in the lap, in other words, we have lapped. we could
     wait for the first new sample point in the next lap. but the GPS inacurracy and the 
     start/finish problem make it pointless to wait for the next point. also when the original
     course was measured, the last point is at the finish line anway.
     
     start a new lap, starting at the end location of the previous lap.
    */
    insist (lastIndex >= 0);
    
    /*this is us making a fresh copy of the location object*/
    Location*startLocation = [[ObjectGraph sharedInstance] addLocationWithTimestamp:location.timestamp
                                                                      latitude:[location.latitude doubleValue]
                                                                     longitude:[location.longitude doubleValue]];
    [self newLapAtLocation:startLocation];
    [self setLapCount]; //this increments the 1's count
    return; //we return here because lastIndex is -1 now, so it means a new lap...
  }
  
  /*
    if the last point in the course is likely to occur sooner than the GPS sample rate, schedule
    an extra GPS sample before then. We throw in extra samples as we approach the finish / start line
    for accuracy in the split timing.
   
    we only schedule a poke for new points we come across, otherwise we'll end up returning here
    constantly for the same point and sampling way too much.
   */
  
  if (index != lastIndex && index >= 0 && index < numCourseLocations - 1)
  {
    /*get how long it took when we measured the course to get from where we are now, to the end.
      presumably with training we are doing this faster now, but we aren't going to ever get twice
      as fast.
     */
   
    Location*lastPoint = [currentCourse.locations lastObject];
    Location*thisPoint = [currentCourse.locations objectAtIndex:index];
    NSTimeInterval timeLeft = [lastPoint.timestamp timeIntervalSinceDate:thisPoint.timestamp];
    insist (timeLeft >= 0);
    
    /*if we aren't expected to get a sample in half that time, make sure we do get one*/
    if (timeLeft < [currentCourse.lapTimeInterval doubleValue] / 2.0)
    {
      log (@"timeLeft is %lf, lapTimeInterval is %lf", timeLeft, [currentCourse.lapTimeInterval doubleValue]);
      /*schedule a new GPS sample in half that time from now. this block will run on the main thread,
        so it's safe to do whatever we want here, for instance mess w/ AppKit or CLLocationManager, etc.
      */
      dispatch_after (dispatch_time(DISPATCH_TIME_NOW, timeLeft / 2.0 * NSEC_PER_SEC),
                      dispatch_get_current_queue(),
                      ^{
                          log (@"poke");
                          [locationCollector poke];
                      });
    }
  }
  
  lastIndex = index;
  [self setLapCount]; //this increments the 10th's count
  
}
 

/*here we start adding points to the course*/
-(IBAction)measureCourse:(id)sender
{
  insist (currentCourse && locationCollector);
  insist ([currentCourse empty]);
  currentCourse.timestamp = [NSDate date]; // this resets elapsed time
  
  locationCollector.timeInterval = [currentCourse.courseTimeInterval doubleValue];
  locationCollector.running = YES;
  
  measureCourseButton.hidden = YES;
  startLapsButton.hidden = YES;
  pauseCourseButton.hidden = NO;
  resumeCourseButton.hidden = YES;
  stopButton.hidden = NO;
  infoButton.hidden = YES;
  lapCountLabel.hidden = YES;
  pauseSeconds = 0;
  
  /*
    it is important the currentPath be up to date before the showTime method is called, since that
    needs to know if we are doing the measurement or if we are doing laps.
  */
  
  currentPath = currentCourse;

  [self showTime];
  [self startTime];
}


/*
  here we start doing laps. this means we make a new workout, add it to the current course, and start
  adding laps to the workout.
 */

-(IBAction)startLaps:(id)sender
{
  insist (currentCourse && locationCollector);
  insist (![currentCourse empty]);
  currentCourse.timestamp = [NSDate date]; // this resets elapsed time

  locationCollector.timeInterval = [currentCourse.lapTimeInterval doubleValue];
  locationCollector.running = YES;
  
  measureCourseButton.hidden = YES;
  startLapsButton.hidden = YES;
  pauseCourseButton.hidden = NO;
  resumeCourseButton.hidden = YES;
  stopButton.hidden = NO;
  infoButton.hidden = YES;
  pauseSeconds = 0;

  /*make a new workout, throw it on the end of the course workout history*/
  Workout*workout = (Workout*)[[ObjectGraph sharedInstance] addObjectNamed:@"Workout"];
  insist (workout);
  [currentCourse addWorkout:workout]; // this makes sure we respect the max workout limit

  [self newLapAtLocation:[self newLocationForCurrentCourseStartAndNow]];
  [self setLapCount];
  lapCountLabel.hidden = NO;
  
  /*now that our currentPath is set (by newLap:), we can mess with the time displays*/
  [self showTime];
  [self startTime];
}

-(IBAction)stop:(id)sender
{
  insist (currentCourse && currentPath);
  locationCollector.running = NO;
  
  startLapsButton.hidden = YES;
  pauseCourseButton.hidden = YES;
  resumeCourseButton.hidden = YES;
  stopButton.hidden = YES;
  infoButton.hidden = NO;
  [self hideTime];
  
  /*if we were measuring a course make sure we got enough points*/

  if (currentPath == currentCourse)
  {
    int numLocations = [currentCourse.locations count];
    if (numLocations < MIN_COURSE_LOCATIONS)
    {
      [[Alert sharedInstance] alertWithTitle:@"GPS Points"
                                     message:[NSString stringWithFormat:@"%d is not enough GPS points for a course measurement. Reduce the GPS course time interval and try again.", numLocations] showCancel:NO];
      [[ObjectGraph sharedInstance] emptyPath:currentPath];
      measureCourseButton.hidden = NO;
      return;
    }
  }
  else
  {
    /*
     we finished a workout, but we might not have actually marked the end, depending on when the GPS is going to
     sample. to make the splits work, we need to make sure that the last lap ends in a location that
     corresponds to when we ended the workout (now), and where the workout ends (at the course start). for other laps
     we can use the next lap's first location to do this math.
     
     */
    
    /*get the course start location*/
    Location*location = [self newLocationForCurrentCourseStartAndNow];
    insist (location);
    insist ([currentCourse.workouts count]);
    Workout*workout = [currentCourse.workouts lastObject];
    insist ([workout.laps count]);
    Lap*lastLap = [workout.laps lastObject];
    insist (lastLap == currentPath);
    [lastLap insertObject:location inLocationsAtIndex:[lastLap.locations count]];
  }
  
  /*we are ready to do laps now, regardless of if we were just measuring or not*/
  startLapsButton.hidden = NO;
}

-(IBAction)pauseCourse:(id)sender
{
  locationCollector.running = NO;

  pauseCourseButton.hidden = YES;
  resumeCourseButton.hidden = NO;
  infoButton.hidden = NO;
  [self stopTime];
  pauseTimestamp = [NSDate date];
}

-(IBAction)resumeCourse:(id)sender
{
  locationCollector.running = YES;

  pauseCourseButton.hidden = NO;
  resumeCourseButton.hidden = YES;
  infoButton.hidden = YES;
  [self startTime];
  
  /*keep track of how much new pause time we incurred*/
  NSDate*now = [NSDate date];
  pauseSeconds += [now timeIntervalSinceDate:pauseTimestamp];
  splitPauseSeconds += [now timeIntervalSinceDate:pauseTimestamp];
}

-(IBAction)toggleLock:(id)sender
{
  locked = !locked;
  buttonsView.hidden = locked;
   
  /*
    if we are locking, hide the info button. otherwise, on unlock, show the info button
    if we are not "running".
   */
  if (locked)
    infoButton.hidden = YES;
  else
    infoButton.hidden = locationCollector.running;
    
  [self setToolbarItemsAnimated:NO];
}

- (void) dealloc
{
  [musicPlayer endGeneratingPlaybackNotifications];
}

/*now that we have user interface elements created, we can modify them*/
- (void)viewDidLoad
{
  [super viewDidLoad];
   
  insist (lockSlider);

  UIImage*left = [[UIImage imageNamed:@"left"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 0)];
  UIImage*right = [[UIImage imageNamed:@"right"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 3, 0, 0)];
  UIImage*thumb = [UIImage imageNamed:@"thumb"];
 
  /*
    we will just are about the extremes, 0 and 1 are fine. when it's at 1.0 that counts as locked.
    the app starts up in the unlocked state and only the user ever changes this, regardeless
    of everything else.
   */
  lockSlider.minimumValue = 0.0;
  lockSlider.maximumValue = 1.0;
  lockSlider.value = lockSlider.maximumValue;
  
  lockSlider.backgroundColor = [UIColor clearColor];
  [lockSlider setThumbImage:thumb forState:UIControlStateNormal];
  [lockSlider setThumbImage:thumb forState:UIControlStateHighlighted];
  [lockSlider setMinimumTrackImage:left forState:UIControlStateNormal];
  [lockSlider setMaximumTrackImage:right forState:UIControlStateNormal];
  [lockSlider addTarget:self action:@selector(lockSliderTouchUp:)
       forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
  [self reset];
  [self setToolbarItemsAnimated:NO];//hides toolbar if no music is playing
  
}

-(void)lockSliderTouchUp:(id)sender
{
  insist (sender && sender == lockSlider);
  if (lockSlider.value == 0.0 || lockSlider.value == 1.0)
  {
    if ((lockSlider.value == 0.0 && !locked) || (lockSlider.value == 1.0 && locked))
      [self toggleLock:sender];
  }
  else
  {
    /*the user didn't manage to slide all the way, return the slider to where it was*/
    [lockSlider setValue:locked ? 0.0 : 1.0 animated:YES];
  }
}
- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return UIInterfaceOrientationIsPortrait (interfaceOrientation);
}

-(void)viewWillAppear:(BOOL)animated
{
  self.navigationController.navigationBarHidden = YES;
  
  /*
    whenever we re-appear, make sure we are in a sane state.
    first get what the current course is supposed to be
  */
  
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  Course*course = [objectGraph mostRecentCourse];
  if (!course)
    course = [objectGraph addCourseWithName:[Course defaultName]];
  insist (course);
  
  /*if the course changed, reset ourselves*/
  if (currentCourse != course)
  {
    [self reset];
    return;
  }
  
  /*otherwise get up to date on the name, the GPS sample rate, and bestGPS settings*/
  
  self.nameLabel.text = course.name;
  locationCollector.timeInterval = currentCourse == currentPath ?
    [currentCourse.courseTimeInterval doubleValue] :
    [currentCourse.lapTimeInterval doubleValue];
  locationCollector.bestGPS = [currentCourse.bestGPS boolValue];

}
@end
