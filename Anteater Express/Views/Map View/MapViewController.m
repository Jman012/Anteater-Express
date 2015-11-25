//
//  MapViewController.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "MapViewController.h"

#import <MapKit/MapKit.h>
#import <SWRevealViewController/SWRevealViewController.h>
#import <TSMessages/TSMessage.h>

@interface MapViewController ()

@property (nonatomic, strong) IBOutlet UIBarButtonItem *revealButton;

@property (nonatomic, strong) IBOutlet MKMapView *mapView;



@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupRevealButton];
    self.title = @"Anteater Express";
    
    // Side menu stuff
    [self.navigationController.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    [[self.mapView.subviews[0] gestureRecognizers] enumerateObjectsUsingBlock:^(UIGestureRecognizer * gesture, NSUInteger idx, BOOL *stop){
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            // We set the delegate for the map view gestures to ourself, so we can cancel
            // any pans starting from the leftmost 30 points.
            [gesture setDelegate:self];
            // And if we tell it to fail, only then can the reveal pan gesture recognizer succeed.
            [self.revealViewController.panGestureRecognizer requireGestureRecognizerToFail:gesture];
        }
    }];
    
    self.revealViewController.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"Enabled");
    self.mapView.userInteractionEnabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"Disabled");
    self.mapView.userInteractionEnabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupRevealButton {
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController)
    {
        [self.revealButton setTarget: self.revealViewController];
        [self.revealButton setAction: @selector(revealToggle:)];
        [[self.revealButton valueForKey:@"view"] addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
}

- (IBAction)testButtonPressed:(id)sender {
    [TSMessage showNotificationInViewController:self
                                          title:@"Test notification"
                                       subtitle:nil
                                          image:nil
                                           type:TSMessageNotificationTypeError
                                       duration:TSMessageNotificationDurationEndless
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                           canBeDismissedByUser:YES];
}

#pragma mark - SWRevealViewController

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position {
    switch (position) {
        case FrontViewPositionLeft:
            self.mapView.userInteractionEnabled = YES;
            break;
            
        default:
            self.mapView.userInteractionEnabled = NO;
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint location = [touch locationInView:self.view];
    CGRect boundingRect = self.mapView.bounds;
    if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        boundingRect.origin.x += 30;
        boundingRect.size.width -= 30;
    }
    
    // If the touch began in the leftmost 30 points, fail so that
    // the reveal pan can work.
    return self.mapView.userInteractionEnabled && CGRectContainsPoint(boundingRect, location);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
