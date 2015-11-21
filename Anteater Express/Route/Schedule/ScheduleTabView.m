//
//  ScheduleTabView.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ScheduleTabView.h"
#import "RouteSchedulesDAO.h"
#import "StopCustomCell.h"
#import "RouteStopDetailsViewController.h"

RouteSchedulesDAO* routeSchedulesDAO;

@interface ScheduleTabView ()

@end

@implementation ScheduleTabView
@synthesize routeData; //NSMutableDictionary
@synthesize stopsList; //Table View of all AStops
@synthesize stopsData; //NSArray of Stops each with their own NSMutableDictionary
@synthesize noStopsMessage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    self.stopsList.dataSource = self;
    
    //To make sure the table view auto sizes
    self.stopsList.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.stopsList.rowHeight = 44;
    
    self.stopsList.delegate = self;
    
    NSString* routeName = [routeData objectForKey:@"Name"];
    
    
    NSString* viewName = @"Route Schedule : ";
    viewName = [viewName stringByAppendingString:routeName];
    self.screenName = viewName;
    
    //Get Route Updates Information
    routeSchedulesDAO = [[RouteSchedulesDAO alloc] initWithRouteName: routeName];
    
    //Load updates into arrays
    stopsData  = [routeSchedulesDAO getRouteStops];
    
    if(!stopsData || !stopsData.count) //If it is empty hide list and let show empty message
    {
        self.stopsList.hidden = YES;
        self.noStopsMessage.hidden = NO;
    }
    else //If it isnt empty then just hide error message
    {
        self.stopsList.hidden = NO;
        self.noStopsMessage.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Do some stuff when the row is selected
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:TRUE];
    //Sets the NavBar title to the Route Name
    UINavigationBar* tabNavBar  = [[self navigationController] navigationBar];
    NSString* routeName         = [routeData objectForKey:@"Name"];
    tabNavBar.topItem.title     = routeName;
    
    
//    //Get Route Updates Information
//    routeSchedulesDAO = [[RouteSchedulesDAO alloc] initWithRouteName: routeName];
//    
//    //Load updates into arrays
//    stopsData  = [routeSchedulesDAO getRouteStops];
//    
//    if(!stopsData || !stopsData.count) //If it is empty hide list and let show empty message
//    {
//        self.stopsList.hidden = YES;
//        self.noStopsMessage.hidden = NO;
//    }
//    else //If it isnt empty then just hide error message
//    {
//        self.stopsList.hidden = NO;
//        self.noStopsMessage.hidden = YES;
//    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    NSLog(@"Selected Index Schedule: %d", self.tabBarController.selectedIndex);

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([[segue identifier]
        isEqualToString:@"StopDetails"]){ //Code for transition to specific stop information
        
        //Sets the NavBar title to the Route Name
        /*UINavigationBar* tabNavBar  = [[self navigationController] navigationBar];
        NSString* routeAbbrev       = [routeData objectForKey:@"Abbreviation"];
        tabNavBar.topItem.title     = routeAbbrev;*/
        
        //Code for transition to selecting a route        
        RouteStopDetailsViewController *stopDetailsViewController = [segue destinationViewController];
        
        stopDetailsViewController.specificStopData = [stopsData objectAtIndex: [self.stopsList indexPathForSelectedRow].row];
        stopDetailsViewController.stopData = [routeSchedulesDAO getStopScheduledTimes:[[[stopsData objectAtIndex: [self.stopsList indexPathForSelectedRow].row] valueForKey:@"StopId"] intValue]];
        stopDetailsViewController.stopSetID = [[routeData objectForKey:@"StopSetId"] intValue];
        stopDetailsViewController.routeName = [routeData objectForKey:@"Name"];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger result = 0;
    if([tableView isEqual:self.stopsList]){
        result = 1;
    }
    return result;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Stops";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;
    if([tableView isEqual:self.stopsList]){
        switch (section) {
            case 0:
            {
                result = [stopsData count];
                break;
            }
        }
    }
    return result;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIndentifier = @"stopCell";
    
    StopCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    
    if(cell == nil) {
        cell = [[StopCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIndentifier];
    }
    
    NSMutableDictionary* tempStop = [stopsData objectAtIndex: indexPath.row];
    
    //Formats the Arrow on the Right Side of each cell
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.stopNameText.text              = [tempStop valueForKey:@"StopName"];
    cell.generalDescriptionText.text    = [tempStop valueForKey:@"StopLocationGenereal"];
    
    //cell.unreadImage.hidden = YES;
    //cell.
    return cell;
    
}

@end
