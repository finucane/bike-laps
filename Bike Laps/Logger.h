//
//  Logger.h
//  Laps
//
//  Created by finucane on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Logger : UIViewController
{
  @private
  int totalLines;
  int maxLines;
  UITextView*textView;
  NSMutableString*logString;
  NSDateFormatter*dateFormatter;
}

- (id)init;
- (void)log:(NSString*)formatString,...;
- (void)setMaxLines:(int)aMaxLines;
+ (Logger*)sharedInstance;

@end

/*turn logging on or off here*/
#if 0
#define log(format,...)[[Logger sharedInstance] log:format, ## __VA_ARGS__]
#else
#define log(format,...)
#endif