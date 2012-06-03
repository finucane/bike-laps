//
//  Alert.h
//  Laps
//
//  Created by finucane on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Alert : NSObject <UIAlertViewDelegate>
{
  @private
  int clickedButtonIndex;
}

+ (id)sharedInstance;
- (BOOL)alertWithTitle:(NSString*)title message:(NSString*)message showCancel:(BOOL)showCancel;

@end;
