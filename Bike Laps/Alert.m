//
//  Alert.m
//  Laps
//
//  Created by finucane on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Alert.h"
#import "insist.h"

@implementation Alert


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  clickedButtonIndex = buttonIndex;
}

/*return YES if the user said OK*/
- (BOOL) alertWithTitle:(NSString*)title message:(NSString*)message showCancel:(BOOL)showCancel
{
 
  UIAlertView*alert = showCancel ?
    [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil]
  :
    [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];

  /*this is our not done indication, a bad index*/
  clickedButtonIndex = -1;
  
  /*show our lovely alert box*/
  [alert show];
  
    /*wait for the alert to be dismissed*/
    while(clickedButtonIndex < 0)
      [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

  insist ((showCancel && clickedButtonIndex <= 1) || clickedButtonIndex == 0);
  
  return showCancel ? clickedButtonIndex == 1 : YES;
}
/*singleton class*/

+ (id)sharedInstance
{
  static dispatch_once_t onceToken = 0;
  __strong static Alert*theAlert = nil;
  dispatch_once(&onceToken, ^{
    theAlert = [[self alloc] init];
  });
  return theAlert;
}

@end
