#//
//  AppDelegate.m
//  Laps
//
//  Created by finucane on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "insist.h"
#import "Logger.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  /*set up the navigation controller*/
  insist (self.navigationController);
  self.window.rootViewController = self.navigationController;
  
  self.navigationController.navigationBarHidden = YES;
  self.navigationController.toolbarHidden = NO;
  
  /*create the laps view controller and push it onto the navigation stack*/
  lapsViewController = [[LapsViewController alloc] initWithNibName:@"LapsViewController" bundle:nil];
  insist (lapsViewController);
  
  [self.navigationController pushViewController:lapsViewController animated:NO];
  
  [self.window makeKeyAndVisible];
  
  /*we don't use location updates in the background because we want fewer samples than continuous
    location updates, and we can't do timers in the background*/
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  [[Logger sharedInstance] setMaxLines:1500];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [[ObjectGraph sharedInstance] save];

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Saves changes in the application's managed object context before the application terminates.
  [[ObjectGraph sharedInstance] save];
}
 
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
  return;
  Logger*logger = [Logger sharedInstance];
  insist (logger);
  
  if (self.navigationController.visibleViewController != logger &&
      self.navigationController.topViewController != logger)
    [self.navigationController.topViewController presentViewController:logger animated:YES completion:nil];
}
@end
