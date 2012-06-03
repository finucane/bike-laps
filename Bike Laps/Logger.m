//
//  Logger.m
//  Laps
//
//  Created by finucane on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Logger.h"
#import "insist.h"

@interface Logger ()

@end

#define BUTTON_HEIGHT 30
#define BUTTON_WIDTH 100
#define MARGIN 10

@implementation Logger

/*this thing assumes ARC*/

- (id)init
{
  self = [super init];
  if (self)
  {
    // Custom initialization
    logString = [[NSMutableString alloc] init];
    textView = nil;
    
    dateFormatter = [[NSDateFormatter alloc] init];
    insist (dateFormatter);
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    totalLines = 0;
    maxLines = -1;//infinite
  }
  return self;
}
;
- (void)loadView
{
  /*make all of the UI programmatically so we can re-use this thing without having .xib files*/
  CGRect statusBarFrame = [[UIApplication sharedApplication]statusBarFrame];
  BOOL statusBarVisible = ![UIApplication sharedApplication].statusBarHidden;
  
  /*make the view*/
  CGRect viewFrame = [[UIScreen mainScreen] bounds];
  if (statusBarVisible)
  { 
    viewFrame.size.height -= statusBarFrame.size.height;
    viewFrame.origin.y = statusBarFrame.size.height;
  }
  self.view = [[UIView alloc] initWithFrame: viewFrame];
  self.view.backgroundColor = [UIColor whiteColor];
  
  textView = [[UITextView alloc]initWithFrame:
              CGRectMake(MARGIN, MARGIN, viewFrame.size.width - 2*MARGIN, viewFrame.size.height - BUTTON_HEIGHT - MARGIN * 4)];
  textView.editable = NO;
  [self.view addSubview:textView];
  
  UIButton*button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  button.frame = CGRectMake(MARGIN, viewFrame.size.height - 2 * MARGIN - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT);
  [button setTitle:@"Clear" forState:UIControlStateNormal];
  [button addTarget:self action:@selector(clear:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];
  

  button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  button.frame = CGRectMake(viewFrame.size.width - MARGIN - BUTTON_WIDTH, viewFrame.size.height - 2 * MARGIN - BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT);
  [button setTitle:@"Done" forState:UIControlStateNormal]; 
  [button addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];

}

-(void)clear:(id)sender
{
  return;//disable for now
  insist (logString && textView);
  [logString setString:@""];
  totalLines = 0;
  [self updateTextViewScrolling:NO];
}

-(void)done:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

}

- (void)setMaxLines:(int)aMaxLines
{
  maxLines = aMaxLines;
}

-(void)updateTextViewScrolling:(BOOL)scrolling
{
  insist (logString);
  
  /*we might not have created the ui yet*/
  if (!textView) return;
  
  /*update the text view contents and scroll to make the last
    character in the log visible, if desired
  */
  
  /*
    never scroll. it is hard to do the nice behavior of not scrolling when
    we are looking through the log because we can't get at the visible range
    programatically. so the lesser of the evils is to at least prevent
    the thing from preventing us from see stuff that we want.
   
    one option is a 3rd button but that is too ugly to be worth the effort.
   */
  scrolling = NO;
  
  textView.text = logString;
  if (scrolling && [logString length])
    [textView scrollRangeToVisible:NSMakeRange([logString length]-1, 1)];
}

/*whenever we come up, make sure the textView is in synch and the bottom is visble*/
- (void)viewWillAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
  [self updateTextViewScrolling:YES];
}

/*
  right now, because i'm in a hurry, this can only be called on the main thread.
  synchronize this and deal w/ modifying ui from any thread later
 */

-(void)log:(NSString*)formatString,...
{
  insist (logString);
  
  /*build the log message from the variable arg list*/
  va_list args;
  va_start(args, formatString);
  NSString*s = [[NSString alloc] initWithFormat:formatString arguments:args];
  va_end(args);
  
  /*
    deal with maxLines. in fact this is going to be an approximation, if the programmer
    himself prints out log entries with newlines we won't truncate enough. but
    we're just trying to bound memory use, this doesn't have to be perfect right now.
   */
  
  int linesToDelete = totalLines - maxLines + 1;
  
  for (int i = 0; i < linesToDelete && totalLines > 0; i++)
  {
     NSRange r = [logString rangeOfString:@"\n"];
    if (r.location == NSNotFound)
      break;
    r = NSMakeRange(0, r.location+1);
    [logString deleteCharactersInRange:r];
    totalLines--;
  } 
  
  totalLines++;
  /*append a timestamp and the message to the log*/
  [logString appendFormat:@"[%@] %@\n", [dateFormatter stringFromDate:[NSDate date]], s];
  
  /*if we are visible, update the textView*/
  if ([self isViewLoaded] && self.view.window)
    [self updateTextViewScrolling:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait (interfaceOrientation);
}

+ (Logger*)sharedInstance
{
  static dispatch_once_t onceToken = 0;
  __strong static Logger*logger = nil;
  dispatch_once(&onceToken, ^{
    logger = [[self alloc] init];
  });
  return logger;
}

@end
