//
//  RouteUpdateDetailsViewController.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteUpdateDetailsViewController.h"

@interface RouteUpdateDetailsViewController ()

@end

@implementation RouteUpdateDetailsViewController
@synthesize updateMessage;
@synthesize updateScreenTitle;
@synthesize updatePostedTime;
@synthesize updateRouteName;
@synthesize updateData;

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
    
    self.navigationItem.backBarButtonItem.title = @"Back";
    
    updateScreenTitle.text = [updateData valueForKey:@"RouteAlertTitle"];
    [updateMessage setText: [updateData valueForKey:@"RouteAlertMessage"]];
    updatePostedTime.text = [NSString stringWithFormat:@"%@ %@", @"Posted: ", [updateData valueForKey:@"RouteAlertTimeStamp"]];
    updateRouteName.text = [NSString stringWithFormat:@"%@ %@", @"Route: ", [updateData valueForKey:@"RouteName"]];
    
    
    NSString* viewName = @"Message : Route : ";
    viewName = [viewName stringByAppendingString:[updateData valueForKey:@"RouteName"]];
    self.trackedViewName = viewName;
}

- (void)viewWillAppear:(BOOL)animated  
{
    [super viewWillAppear:true];
    // Do any items that we want to happen before appearance.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
