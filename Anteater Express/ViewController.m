//
//  ViewController.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "RoutesAndAnnounceDAO.h"
#import "RouteUpdatesDAO.h"

#import "ViewController.h"
#import "AllRouteUpdates.h"
#import "AnnouncementsAndNews.h"
#import "SelectRoute.h"
#import "RouteTabView.h"
#import "ScheduleTabView.h"
#import "UpdateTabView.h"
#import "Utilities.h"
#import "NoConnectionViewController.h"

#import "ColorConverter.h"
#import <QuartzCore/QuartzCore.h>

RoutesAndAnnounceDAO* dao;
RouteUpdatesDAO* routeUpdatesDAO;

@interface ViewController ()

@end

@implementation ViewController

@synthesize allRoutes;
@synthesize selectRoutePicker;
@synthesize activityView;

NSInteger selectedRouteID;
NSInteger selectedPickerRow;
NSMutableDictionary* selectedRoute;
NSInteger hasNetworkConnection;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.trackedViewName = @"Welcome";
	// Do any additional setup after loading the view, typically from a nib.
    
    dao = [[RoutesAndAnnounceDAO alloc] init];
    routeUpdatesDAO = [[RouteUpdatesDAO alloc] initWithRouteName: @"All"];
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    self.selectRoutePicker.dataSource = self;
    
    self.selectRoutePicker.delegate = self;
    
    [self.selectRoutePicker setHidden:YES];
    
    selectRoutePicker.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerTap:)];
    [selectRoutePicker addGestureRecognizer:tapGesture];
    selectedPickerRow = 0;
    
}
- (void)pickerTap: (UIGestureRecognizer*) gestureRecognizer
{
    
    //Find out where the user tapped
    CGFloat myPositionY = [gestureRecognizer locationInView: selectRoutePicker].y;
    
    //Height of picker row (divided into 5 equal parts)
    CGFloat rowHeight = selectRoutePicker.frame.size.height/5;
    
    //Variable to hold the selected row
    NSInteger selectedRowIndex = [selectRoutePicker selectedRowInComponent:0];
    
    
    //Check if any action is needed.
    // We consider anything above the currently selected item as one above the selected item.
    // Similarly, anything below the currently selected item is one below the selected item.
    
    if(myPositionY < 2*rowHeight) // above center
    {
        selectedRowIndex -= ([selectRoutePicker selectedRowInComponent:0] > 0? 1 : 0);
    }
    else if(myPositionY < 3*rowHeight ) // center
    {
        selectedRowIndex = [selectRoutePicker selectedRowInComponent:0]; // originally selected component.
        
        //they double clicked?
        //NSLog(@"Picker Selected Object");
        //NSLog(@"%i", selectedPickerRow);
        //NSLog(@"Current Selection Was:");
        //NSLog(@"%i", [selectRoutePicker selectedRowInComponent:0]);
        NSMutableDictionary* tempRoute = [allRoutes objectAtIndex: selectedRowIndex];
        
        //To set for the segue to the route
        selectedRoute = tempRoute;
        
        //NSLog(@"%@", tempRoute);
        // NSLog(@"Data Content:  %@", tempRoute );
        
        // NSLog(@"ROUTE ID TO BE STORED: %i", routeID);
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        //Saving RouteID an int
        int routeID = [[tempRoute valueForKey:@"Id"] intValue];
        [prefs setInteger:routeID forKey:@"selectedRouteID"];
        
        NSString* routeTitle;
        NSString* routeHexColor;
        NSString* routeTextHexColor;
        
        ColorConverter *colorConvert = [[ColorConverter alloc] init];
        
        if(tempRoute != nil) //Set button to selectedRoute if it was found
        {
            routeTitle = [tempRoute valueForKey:@"Name"];
            routeHexColor = [tempRoute valueForKey:@"ColorHex"];
            routeTextHexColor = [tempRoute valueForKey:@"TextColorHex"];
        }
        else { //There was no valid route  selected
            routeTitle = @"Select a Route";
            routeHexColor = @"FFFFFF";
            routeTextHexColor = @"000000";
        }
        
        
        UIColor * routeColor = [colorConvert colorWithHexString:routeHexColor];
        UIColor * routeTextColor = [colorConvert colorWithHexString:routeTextHexColor];
        
        [selectRouteButton setTitle:routeTitle forState:UIControlStateNormal];
        [selectRouteButton setTitleColor:routeTextColor forState:UIControlStateNormal];
        [selectRouteButton setTitleColor:routeTextColor forState:UIControlStateSelected];
        [selectRouteButton setTitleColor:routeTextColor forState:UIControlStateHighlighted];
        [selectRouteButton setBackgroundColor:routeColor];
        //END BUTTON CHANGES
        
        [self.selectRoutePicker setHidden:YES];
    }
    else // below center
    {
        selectedRowIndex += ([selectRoutePicker selectedRowInComponent:0] < [selectRoutePicker numberOfRowsInComponent:0]-1? 1 : 0);
    }
    
    [selectRoutePicker selectRow:selectedRowIndex inComponent:0 animated:YES];
    
}

- (void)viewDidUnload
{
    selectRouteButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //Route Updates DAO repopulated on every reappearance so that it will not just show only 1 route if the user has already looked at a route
    
    dao = [[RoutesAndAnnounceDAO alloc] init];
    routeUpdatesDAO = [[RouteUpdatesDAO alloc] initWithRouteName: @"All"];
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [self.selectRoutePicker setHidden:YES];
    
    // getting an NSInteger
    selectedRouteID = [prefs integerForKey:@"selectedRouteID"];
    
    //NSLog(@"Selected RouteID: %i", selectedRouteID);
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    //NSArray* allRoutes = [dao getRoutes];
    allRoutes = [dao getRoutes];
    selectedRoute = nil;
    
    for(NSMutableDictionary *tempRoute in allRoutes)
    {
        if([[tempRoute valueForKey:@"Id"] intValue] == selectedRouteID)
        {
            selectedRoute = tempRoute;
        }
    }
    
    NSString* routeTitle;
    NSString* routeHexColor;
    NSString* routeTextHexColor;
    
    ColorConverter *colorConvert = [[ColorConverter alloc] init];
    
    if(selectedRoute != nil) //Set button to selectedRoute if it was found
    {
        routeTitle = [selectedRoute valueForKey:@"Name"];
        routeHexColor = [selectedRoute valueForKey:@"ColorHex"];
        routeTextHexColor = [selectedRoute valueForKey:@"TextColorHex"];
    }
    else { //There was no valid route  selected
        routeTitle = @"Select a Route";
        routeHexColor = @"FFFFFF";
        routeTextHexColor = @"000000";
    }
    
    
    UIColor * routeColor = [colorConvert colorWithHexString:routeHexColor];
    UIColor * routeTextColor = [colorConvert colorWithHexString:routeTextHexColor];
    
    [selectRouteButton setTitle:routeTitle forState:UIControlStateNormal];
    [selectRouteButton setTitleColor:routeTextColor forState:UIControlStateNormal];
    [selectRouteButton setTitleColor:routeTextColor forState:UIControlStateSelected];
    [selectRouteButton setTitleColor:routeTextColor forState:UIControlStateHighlighted];
    [selectRouteButton setBackgroundColor:routeColor];
    
    //Round edges of select route button
    selectRouteButton.layer.cornerRadius = 10;
    selectRouteButton.clipsToBounds = YES;
    
    /*//Create shiny layer on top
     CAGradientLayer *shineLayer = [CAGradientLayer layer];
     shineLayer.frame = selectRouteButton.layer.bounds;
     //Set the gradient colors
     shineLayer.colors = [NSArray arrayWithObjects:
     (id)[UIColor colorWithWhite: 1.0f alpha:0.4f].CGColor,
     (id)[UIColor colorWithWhite: 1.0f alpha:0.2f].CGColor,
     (id)[UIColor colorWithWhite: 0.75f alpha:0.2f].CGColor,
     (id)[UIColor colorWithWhite: 0.4f alpha:0.2f].CGColor,
     (id)[UIColor colorWithWhite: 1.0f alpha:0.4f].CGColor,
     nil];
     //Set the relative positions of the gradient stops
     shineLayer.locations = [NSArray arrayWithObjects:
     [NSNumber numberWithFloat: 0.0f],
     [NSNumber numberWithFloat: 0.5f],
     [NSNumber numberWithFloat: 0.5f],
     [NSNumber numberWithFloat: 0.8f],
     [NSNumber numberWithFloat: 1.0f],
     nil];
     //Add the layer to the button
     [selectRouteButton.layer addSublayer:shineLayer];*/
}

- (IBAction)goToRouteSelectedButtonPress:(id)sender
{
    if(selectedRoute != nil)
    {
        [self performSegueWithIdentifier:@"ShowSelectedRoute" sender:self];
    }
    else
    {
        UIAlertView *noRouteSelectedAlert = [[UIAlertView alloc] initWithTitle:@"No Route Selected" message:@"Please select a route and try again!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [noRouteSelectedAlert show];
    }
}

- (IBAction)selectRouteButtonPress:(id)sender {
    //Gives selected color as user clicks button before segue happens
    //Note: Segue is handled via storyboard, not at this spot in the code
    [sender setBackgroundColor:[UIColor blueColor]];
    [sender setTitleColor:[UIColor whiteColor] forState: UIControlStateNormal];
    [self.selectRoutePicker setHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [activityView stopAnimating];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)startProgressIndicator:(id)sender
{
    if(![activityView isAnimating])
    {
        [activityView startAnimating];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    [NSThread detachNewThreadSelector:@selector(startProgressIndicator:) toTarget:self withObject:nil];
    
    /*NSLog(@"Source Controller = %@", [segue sourceViewController]);
     NSLog(@"Destination Controller = %@", [segue destinationViewController]);
     NSLog(@"Segue Identifier = %@", [segue identifier]);*/
    
    if([[segue identifier]
        isEqualToString:@"ShowAnnouncementsNews"]){ //Code for transition to announcements/news
        
        AnnouncementsAndNews *viewController = [segue destinationViewController];
        
        dao = [[RoutesAndAnnounceDAO alloc] init];
        viewController.announcementsData = [dao getServiceAnnouncements];
    }
    else if([[segue identifier]
             isEqualToString:@"ShowAllRouteUpdates"]){ //Code for transition to all route updates
        
        AllRouteUpdates *viewController = [segue destinationViewController];
        
        routeUpdatesDAO = [[RouteUpdatesDAO alloc] initWithRouteName: @"All"];
        viewController.updatesData = [routeUpdatesDAO getRouteUpdates];
    }
    else if([[segue identifier]
             isEqualToString:@"ShowSelectRoutes"])
    {
        //Code for transition to selecting a route
        SelectRoute *routeViewController = [segue destinationViewController];
        routeViewController.routesData = [dao getRoutes];
    }
    else if([[segue identifier]
             isEqualToString:@"ShowMenu"])
    {
        //Code for transition to menu
    }
    else if([[segue identifier]
             isEqualToString:@"ShowSelectedRoute"])
    {
        //Code for transition to a selected route
        UITabBarController *routeTabController = [segue destinationViewController];
        
        //NSLog(@"Child: %@", [routeTabController childViewControllers]);
        RouteTabView *routeTabViewController = [[routeTabController childViewControllers] objectAtIndex:0];
        routeTabViewController.routeData = selectedRoute;
        ScheduleTabView *routeScheduleViewController = [[routeTabController childViewControllers] objectAtIndex:1];
        routeScheduleViewController.routeData = selectedRoute;
        
        UpdateTabView *routeUpdateVViewController = [[routeTabController childViewControllers] objectAtIndex:2];
        routeUpdateVViewController.routeData = selectedRoute;
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger result = 0;
    if([pickerView isEqual:self.selectRoutePicker])
    {
        result = 1;
        //[[dao getRoutes] count];
    }
    return result;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    NSInteger result = 0;
    if ([pickerView isEqual:self.selectRoutePicker])
    {
        //result = 10;
        result = [[dao getRoutes] count];
    }
    return result;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *result = nil;
    if ([pickerView isEqual:self.selectRoutePicker])
    {
        NSMutableDictionary* tempRoute = [allRoutes objectAtIndex: row];
        
        NSString* routeName = [tempRoute valueForKey:@"Name"];
        NSString* colorName = [tempRoute valueForKey:@"ColorName"];
        
        result = [NSString stringWithFormat:@"%@ (%@)", routeName, colorName];
        //result = routeName;
        //NSString* textHexColor = [tempRoute valueForKey:@"TextColorHex"];
        //NSString* hexColor = [tempRoute valueForKey:@"ColorHex"];
        //result = [NSString stringWithFormat:@"Row %ld", (long)row+1];
    }
    return result;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    selectedPickerRow = row;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //True when user clicks "OK" button.
    if (buttonIndex == 0) {
        
    }
}


@end
