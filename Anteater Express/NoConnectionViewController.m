//
//  NoConnectionViewController.m
//  Anteater Express
//
//  Created by Andrew Beier on 3/2/13.
//
//

#import "NoConnectionViewController.h"
#import "Utilities.h"
#import "ViewController.h"

@interface NoConnectionViewController ()

@end

@implementation NoConnectionViewController

@synthesize retryButton;

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
    self.screenName = @"No Connection Screen";
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)retryConnection:(id)sender
{
 // disable button
    [retryButton setEnabled:NO];
    NSInteger hasConnection = [Utilities checkNetworkStatus];
    if(hasConnection == 0)
    {
       // ViewController *mainPage = [self.storyboard instantiateViewControllerWithIdentifier:@"AntExHome"];
       // [self.navigationController popToViewController: mainPage animated: NO];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    // enable button again in else
    [retryButton setEnabled:YES];
}

@end
