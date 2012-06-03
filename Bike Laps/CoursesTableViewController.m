//
//  CoursesTableViewController.m
//  Laps
//
//  Created by finucane on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CoursesTableViewController.h"
#import "ObjectGraph.h"
#import "CourseTableViewController.h"

#import "insist.h"

@implementation CoursesTableViewController

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (!self)
    return nil; 
  
  /*set up the toolbar*/
  editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
  doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
  addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
  spaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  
  [self setToolbarWithEdit];
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)setToolbarWithEdit
{
  [self setToolbarItems:[NSArray arrayWithObjects:editButton, spaceButton, addButton, nil]];
}

- (void)setToolbarWithDone
{
  [self setToolbarItems:[NSArray arrayWithObjects:doneButton, spaceButton, addButton, nil]];
}

-(void)add:(id)sender
{
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  insist (objectGraph);
  [objectGraph addCourseWithName:[Course defaultName]];
  [self.tableView reloadData];
}

-(void)edit:(id)sender
{
  [self.tableView setEditing:YES];
  [self setToolbarWithDone];
}

-(void)done:(id)sender
{
  [self.tableView setEditing:NO];
  [self setToolbarWithEdit];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  insist (objectGraph);
  return [objectGraph.courses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  insist (objectGraph);
   
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
  if (!cell)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  int row = [indexPath row];
  insist (row >= 0 && row < [objectGraph.courses count]);
  Course*course = [objectGraph.courses objectAtIndex:row];
  insist (course);
  
  cell.textLabel.text = course.name;
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  cell.imageView.image = course == [objectGraph mostRecentCourse] ?
    [UIImage imageNamed:@"checkmark"] : [UIImage imageNamed:@"whiteCheckmark"];
              
    // Configure the cell...
    
    return cell;
}
 

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
      int row = [indexPath row];
      ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
      Course*course = [objectGraph.courses objectAtIndex:row];
      [objectGraph removeCourse:course];
       
      // Delete the row from the data source
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      
      /*this will update the checkmark*/
      [tableView reloadData];
      
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
    }   
}


/*
 to move rows around, we change the listOrder values of the courses
*/
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  insist (objectGraph);
  [objectGraph moveCourseFrom:[fromIndexPath row] to:[toIndexPath row]];
  [tableView reloadData];
}

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  insist (objectGraph);
  Course*course = [objectGraph.courses objectAtIndex:[indexPath row]];
  insist (course);
  
  /*touch the course.*/
  course.timestamp = [NSDate date];
  [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
  ObjectGraph*objectGraph = [ObjectGraph sharedInstance];
  insist (objectGraph);
  Course*course = [objectGraph.courses objectAtIndex:[indexPath row]];
  insist (course);
  
  CourseTableViewController*controller = [[CourseTableViewController alloc] initWithNibName:@"CourseTableViewController" bundle:nil course:course];
  [self.navigationController pushViewController:controller animated:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
  self.navigationController.navigationBarHidden = NO;
  self.navigationController.toolbarHidden = NO;
  [self.tableView reloadData];
  [super viewWillAppear:animated];
}
@end
