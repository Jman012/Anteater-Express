//
//  ParentCustomViewController.m
//  Anteater Express
//
//  Created by Andrew Beier on 3/2/13.
//
//

#import "ParentCustomViewController.h"
#import "Utilities.h"
#import "NoConnectionViewController.h"

@interface ParentCustomViewController ()

@end

@implementation ParentCustomViewController

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
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    NSInteger hasNetworkConnection = [Utilities checkNetworkStatus];
    
    if(hasNetworkConnection == 1)
    {
        NoConnectionViewController* noConnection = [self.storyboard instantiateViewControllerWithIdentifier:@"NOCONNECTION"];
        [self.navigationController pushViewController:noConnection animated:NO];
    }
    else if(hasNetworkConnection == 2)
    {
        NoConnectionViewController* noConnection = [self.storyboard instantiateViewControllerWithIdentifier:@"NOCONNECTION"];
        [self.navigationController pushViewController:noConnection animated:NO];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
