//
//  AnnouncementDetailsViewController.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnnouncementDetailsViewController.h"

@interface AnnouncementDetailsViewController ()

@end

@implementation AnnouncementDetailsViewController
@synthesize newsTitle;
@synthesize newsMessage;
@synthesize newsScreenTitle;
@synthesize newsPostedTime;
@synthesize newsData;

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
    self.screenName = @"Message : General News";
	// Do any additional setup after loading the view.
    
    self.navigationItem.backBarButtonItem.title = @"Back";
    //self.navigationItem.title = newsTitle; //Set navbar title to say the News Title
    
    newsScreenTitle.text = [newsData valueForKey:@"GlobalAlertTitle"];
    [newsMessage setText: [newsData valueForKey:@"GlobalAlertMessage"]];
    newsPostedTime.text = [NSString stringWithFormat:@"%@ %@", @"Posted: ", [newsData valueForKey:@"GlobalAlertTimeStamp"]];
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
