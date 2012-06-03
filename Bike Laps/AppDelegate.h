//
//  AppDelegate.h
//  Laps
//
//  Created by finucane on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LapsViewController.h"
#import "ObjectGraph.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
  @private
  LapsViewController*lapsViewController;
}

@property (nonatomic, strong) IBOutlet UIWindow*window;
@property (nonatomic, weak) IBOutlet UINavigationController*navigationController;

@end
