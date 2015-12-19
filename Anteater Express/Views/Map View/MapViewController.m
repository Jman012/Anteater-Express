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

#import "AEGetRouteDefinition.h"
#import "ColorConverter.h"

@interface MapViewController ()

@property (nonatomic, strong) IBOutlet UIBarButtonItem *revealButton;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) NSDictionary *allRoutes; // Holds entire Route dicts, keyed by the route "Id"
@property (nonatomic, strong) NSMutableSet *selectedRoutes; // Holds the "Id" for each route, which is used in the allRoutes dict.
@property (atomic, strong) NSMutableDictionary *routeDefinitions; // Holds the route def dicts, keyed by the StopSetId
@property (nonatomic, strong) NSMutableDictionary *routeDefinitionsPolylines; // Made from routDefs, holds the MKPolylines by routeId
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, assign) MKMapPoint northEastPoint;
@property (nonatomic, assign) MKMapPoint southWestPoint;




@end

@implementation MapViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.name = @"Map View Controller";
        
        self.mapView.delegate = self;
        
        self.selectedRoutes = [NSMutableSet set];
        self.routeDefinitions = [NSMutableDictionary dictionary];
        self.routeDefinitionsPolylines = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupRevealButton];
    self.title = @"Anteater Express";
    
    // Side menu stuff
    [self.navigationController.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    [[self.mapView.subviews[0] gestureRecognizers] enumerateObjectsUsingBlock:^(UIGestureRecognizer * gesture, NSUInteger idx, BOOL *stop){
        if ([gesture isMemberOfClass:[UIPanGestureRecognizer class]]) {
            // We set the delegate for the map view gestures to ourself, so we can cancel
            // any pans starting from the leftmost 30 points.
            [gesture setDelegate:self];
            // And if we tell it to fail, only then can the reveal pan gesture recognizer succeed.
            [self.revealViewController.panGestureRecognizer requireGestureRecognizerToFail:gesture];
        }
    }];
    
    self.revealViewController.delegate = self;
    
    [self.mapView setMapType:MKMapTypeStandard];
    self.mapView.delegate = self;

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

#pragma mark - Route Data handling

- (void)setAllRoutesArray:(NSArray *)allRoutesArray {
    // Construct a dict of these where each key is the Id
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSDictionary *routeDict in allRoutesArray) {
        NSNumber *routeId = routeDict[@"Id"];
        dict[routeId] = routeDict;
    }
    self.allRoutes = dict;
}

- (void)setAllRoutes:(NSDictionary *)allRoutes {
    _allRoutes = allRoutes;
    
    // Now that our routes got set, lets load all the data we need
    // Note: This might be just an update, so make sure we're not reloading
    // unnecessary data

    for (NSNumber *routeId in _allRoutes) {
        NSDictionary *routeDict = _allRoutes[routeId];
        NSNumber *routeStopSetId = routeDict[@"StopSetId"];
        
        if (self.routeDefinitions[routeId] == nil) {
            // If our route Definitions (which hold 1. the gps coords and 2. the stops)
            // Then we'll dl it.
            
            AEGetRouteDefinition *getRouteOp = [[AEGetRouteDefinition alloc] initWithStopSetId:[routeStopSetId integerValue]];
            getRouteOp.returnBlock = ^(RouteDefinitionDAO *routeDefinition) {
                
                // Set routeDefinitions
                self.routeDefinitions[routeId] = routeDefinition;
                
                // Set routeDefinitionsMapPoints
                NSArray *routePoints = [self.routeDefinitions[routeId] getRoutePoints];
                MKMapPoint *routeMapPointsCArray = malloc(sizeof(MKMapPoint) * routePoints.count);
                // Make C Array
                double oldNEX = self.northEastPoint.x;
                double oldNEY = self.northEastPoint.y;
                double oldSWX = self.southWestPoint.x;
                double oldSWY = self.southWestPoint.y;
                [routePoints enumerateObjectsUsingBlock:^(NSDictionary *curPointDict, NSUInteger idx, BOOL *stop) {
                    CLLocationDegrees latitude  = [[curPointDict objectForKey:@"Latitude"] doubleValue];
                    CLLocationDegrees longitude = [[curPointDict objectForKey:@"Longitude"] doubleValue];
                    
                    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                    MKMapPoint point = MKMapPointForCoordinate(coordinate);
                    routeMapPointsCArray[idx] = point;
                    
                    // While we're here, update the bounding points
                    // If no bound points are set yet, initialize them
                    if (self.northEastPoint.x == 0 && self.northEastPoint.y == 0) {
                        self.northEastPoint = point;
                    }
                    if (self.southWestPoint.x == 0 && self.southWestPoint.y == 0) {
                        self.southWestPoint = point;
                    }
                    
                    // And here, we'll update based on new points
                    if (point.x > self.northEastPoint.x)
                        self.northEastPoint = MKMapPointMake(point.x, self.northEastPoint.y);
                    if(point.y > self.northEastPoint.y)
                        self.northEastPoint = MKMapPointMake(self.northEastPoint.x, point.y);
                    if (point.x < self.southWestPoint.x)
                        self.southWestPoint = MKMapPointMake(point.x, self.southWestPoint.y);
                    if (point.y < self.southWestPoint.y)
                        self.southWestPoint = MKMapPointMake(self.southWestPoint.x, point.y);

                }];
                // Make the polyline object out of the coords and add to the dict
                MKPolyline *polyline = [MKPolyline polylineWithPoints:routeMapPointsCArray count:routePoints.count];
                [polyline setTitle:[routeId stringValue]];
                self.routeDefinitionsPolylines[routeId] = polyline;
                
                if (oldNEX != self.northEastPoint.x || oldNEY != self.northEastPoint.y ||
                    oldSWX != self.southWestPoint.x || oldSWY != self.southWestPoint.y) {
                    CGFloat MAP_POINT_PADDING = 1000;
                    CGFloat MAP_LENGTH_PADDING = MAP_POINT_PADDING * 2;
                    
                    MKMapRect bounds = MKMapRectMake(self.southWestPoint.x - MAP_POINT_PADDING, self.southWestPoint.y - MAP_POINT_PADDING, self.northEastPoint.x - self.southWestPoint.x + MAP_LENGTH_PADDING, self.northEastPoint.y - self.southWestPoint.y + MAP_LENGTH_PADDING);
                    [self.mapView setVisibleMapRect:bounds animated:YES];
                    
                }

                
            };
            [self.operationQueue addOperation:getRouteOp];
        }
    }
}

#pragma mark - Route selection methods

- (void)showNewRoute:(NSNumber *)theId {
    NSLog(@"Showing new route: %@", theId);
    [self.selectedRoutes addObject:theId];
    
    if (self.routeDefinitionsPolylines[theId] != nil) {
        [self.mapView addOverlay:self.routeDefinitionsPolylines[theId]];
    }
}

- (void)removeRoute:(NSNumber *)theId {
    NSLog(@"Removing route: %@", theId);
    [self.selectedRoutes removeObject:theId];
    
    
    if (self.routeDefinitionsPolylines[theId] != nil) {
        [self.mapView removeOverlay:self.routeDefinitionsPolylines[theId]];
    }
}

- (void)clearAllRoutes {
    [self.selectedRoutes removeAllObjects];
    [self.mapView removeOverlays:self.mapView.overlays];
}

#pragma mark - MapKit methods

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyline = (MKPolyline *)overlay;
        NSNumber *routeId = [NSNumber numberWithInteger:polyline.title.integerValue];
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        
        ColorConverter *colorConverter = [[ColorConverter alloc] init];
        renderer.strokeColor = [colorConverter colorWithHexString:self.allRoutes[routeId][@"ColorHex"]];
        renderer.lineWidth = 4.0f;
        
        return renderer;
    }
    
    return nil;
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
