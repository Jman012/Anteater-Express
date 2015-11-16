//
//  ServicesViewController.m
//  Anteater Express
//
//  Created by Andrew Beier on 1/4/13.
//
//

#import "ServicesViewController.h"

@interface ServicesViewController ()

@end

@implementation ServicesViewController

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
    self.trackedViewName = @"Info : Services";
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    
    //Sets the NavBar title
    UINavigationBar* tabNavBar  = [[self navigationController] navigationBar];
    NSString* titleName         = @"Services";
    tabNavBar.topItem.title     = titleName;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    //Sets the NavBar title
    UINavigationBar* tabNavBar  = [[self navigationController] navigationBar];
    NSString* titleName         = @"Services";
    tabNavBar.topItem.title     = titleName;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
