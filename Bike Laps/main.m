//
//  main.m
//  Laps
//
//  Created by finucane on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Alert.h"
int main(int argc, char *argv[])
{
  @autoreleasepool
  {
    @try
    {
      return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
    @catch (NSException *exception)
    {
    //  [[Alert sharedInstance] alertWithTitle:@"Bug" message:[exception reason] showCancel:NO];
      NSLog (@"%@", [exception reason]);
    }
    @finally
    {
      
    }
  }
}