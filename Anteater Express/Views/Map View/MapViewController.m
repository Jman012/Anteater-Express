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

#import "AEStopAnnotation.h"

@interface MapViewController ()

@property (nonatomic, strong) IBOutlet UIBarButtonItem *revealButton;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;

// Basic/wholistic route info
@property (nonatomic, strong) NSDictionary<NSNumber*, NSDictionary*> *allRoutes; // Holds entire Route dicts, keyed by the route "Id"
@property (nonatomic, strong) NSMutableSet<NSNumber*> *selectedRoutes; // Holds the "Id" for each route, which is used in the allRoutes dict.
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, RouteDefinitionDAO*> *routeDefinitions; // Holds the route def dicts, keyed by the StopSetId
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, MKPolyline*> *routeDefinitionsPolylines; // Made from routDefs, holds the MKPolylines by routeId

// Route Stop information specifically
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSArray<NSNumber*>*> *routeStopsForWhichLines; // RouteId -> @[StopSetId], used as a lookup
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, AEStopAnnotation*> *routeStopsAnnotationsDict; // Just holds the MapAnnotation objects. StopId->AEStopAnnotation.
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *routeStopsAnnotationsSelected; // Routes share stops, so this is StopId->count as a retain/release method

// Misc
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) MKMapPoint northEastPoint;
@property (nonatomic, assign) MKMapPoint southWestPoint;
@property (nonatomic, strong) CLLocationManager *locationManager;




@end

@implementation MapViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.name = @"Map View Controller";
        
        self.mapView.delegate = self;

        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager requestWhenInUseAuthorization];
        CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
        if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
            authStatus == kCLAuthorizationStatusAuthorizedAlways) {
            [self.locationManager startUpdatingLocation];
            self.mapView.showsUserLocation = YES;
        }
        
        self.selectedRoutes = [NSMutableSet set];
        self.routeDefinitions = [NSMutableDictionary dictionary];
        self.routeDefinitionsPolylines = [NSMutableDictionary dictionary];
        self.routeStopsAnnotationsDict = [NSMutableDictionary dictionary];
        self.routeStopsAnnotationsSelected = [NSMutableDictionary dictionary];
        self.routeStopsForWhichLines = [NSMutableDictionary dictionary];
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

- (void)setMapType:(MKMapType)newType {
    if (newType != self.mapView.mapType) {
        [self.mapView setMapType:newType];
    }
}

#pragma mark - Route Data handling

- (NSArray *)routeIdsForStopId:(NSNumber *)stopId {
    __block NSMutableArray *toRet = [NSMutableArray array];
    [self.routeStopsForWhichLines enumerateKeysAndObjectsUsingBlock:^(NSNumber *curRouteId, NSArray *stopIdArray, BOOL *stop) {
        [stopIdArray enumerateObjectsUsingBlock:^(NSNumber *curStopId, NSUInteger idx, BOOL *stop2) {
            if ([stopId isEqualToNumber:curStopId]) {
                [toRet addObject:curRouteId];
            }
        }];
    }];
    return toRet;
}

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
            
            [self downloadNewRouteInfoWithId:routeId stopSetId:routeStopSetId];
            
        }
    }
}

- (void)downloadNewRouteInfoWithId:(NSNumber *)routeId stopSetId:(NSNumber *)routeStopSetId {
    AEGetRouteDefinition *getRouteOp = [[AEGetRouteDefinition alloc] initWithStopSetId:[routeStopSetId integerValue]];
    getRouteOp.returnBlock = ^(RouteDefinitionDAO *routeDefinition) {
        
        // Set routeDefinitions
        self.routeDefinitions[routeId] = routeDefinition;
        
        
        /* ROUTE LINE */
        // Set routeDefinitionsMapPoints for the route line
        NSArray *routePoints = [self.routeDefinitions[routeId] getRoutePoints];
        MKMapPoint *routeMapPointsCArray = malloc(sizeof(MKMapPoint) * routePoints.count);
        // Make C Array
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
            
        }];
        // Make the polyline object out of the coords and add to the dict
        MKPolyline *polyline = [MKPolyline polylineWithPoints:routeMapPointsCArray count:routePoints.count];
        [polyline setTitle:[routeId stringValue]];
        self.routeDefinitionsPolylines[routeId] = polyline;
        
        
        /* ROUTE STOPS */
        NSArray *routeStops = [self.routeDefinitions[routeId] getRouteStops];
        NSMutableArray *stopNumbersForTheRoute = [NSMutableArray arrayWithCapacity:routeStops.count];
        [routeStops enumerateObjectsUsingBlock:^(NSDictionary *curStopDict, NSUInteger idx, BOOL *stop) {
            NSNumber *stopId = curStopDict[@"StopId"];
            [stopNumbersForTheRoute addObject:curStopDict[@"StopId"]];
            if (self.routeStopsAnnotationsDict[stopId] == nil) {
                // No annotation set, make a new annotation and assign it to this stopId
                AEStopAnnotation *newStopAnnotation = [[AEStopAnnotation alloc] initWithDictionary:[curStopDict copy]];
                self.routeStopsAnnotationsDict[stopId] = newStopAnnotation;
            } else {
                // There exists an annotation, so just add the dict to it.
                AEStopAnnotation *stopAnnotation = self.routeStopsAnnotationsDict[stopId];
                [stopAnnotation addNewDictionary:curStopDict];
                // TODO: reload it somehow if it's one the screen currently?
            }
        }];
        self.routeStopsForWhichLines[routeId] = stopNumbersForTheRoute;
        
        NSArray *annotations = self.mapView.annotations;
        [self.mapView removeAnnotations:annotations];
        [self.mapView addAnnotations:annotations];
    };
    [self.operationQueue addOperation:getRouteOp];
}

#pragma mark - Route selection methods

- (void)showNewRoute:(NSNumber *)theId {
    NSLog(@"Showing new route: %@", theId);
    [self.selectedRoutes addObject:theId];
    
    // Add the route lines to the map
    if (self.routeDefinitionsPolylines[theId] != nil) {
        [self.mapView addOverlay:self.routeDefinitionsPolylines[theId]];
    }
    // Add the route stops to the map
    if (self.routeStopsForWhichLines[theId] != nil) {
        [self.routeStopsForWhichLines[theId] enumerateObjectsUsingBlock:^(NSNumber *stopId, NSUInteger idx, BOOL *stop) {
            AEStopAnnotation *stopAnnotation = self.routeStopsAnnotationsDict[stopId];
            if (self.routeStopsAnnotationsSelected[stopId] == nil) {
                // Doesn't exist on map yet
                self.routeStopsAnnotationsSelected[stopId] = @1;
                [self.mapView addAnnotation:stopAnnotation];
            } else {
                // Exists, so just up the counter
                NSNumber *curCount = self.routeStopsAnnotationsSelected[stopId];
                self.routeStopsAnnotationsSelected[stopId] = [NSNumber numberWithInteger:curCount.integerValue + 1];
                
                // Then reload the annotation to refresh the view
                [self.mapView removeAnnotation:stopAnnotation];
                [self.mapView addAnnotation:stopAnnotation];
            }
            
        }];
    }
}

- (void)removeRoute:(NSNumber *)theId {
    NSLog(@"Removing route: %@", theId);
    [self.selectedRoutes removeObject:theId];
    
    // Remove the route line
    if (self.routeDefinitionsPolylines[theId] != nil) {
        [self.mapView removeOverlay:self.routeDefinitionsPolylines[theId]];
    }
    // Remove the route stops
    if (self.routeStopsForWhichLines[theId] != nil) {
        [self.routeStopsForWhichLines[theId] enumerateObjectsUsingBlock:^(NSNumber *stopId, NSUInteger idx, BOOL *stop) {
            AEStopAnnotation *stopAnnotation = self.routeStopsAnnotationsDict[stopId];
            if (self.routeStopsAnnotationsSelected[stopId] != nil) {
                // There currently is a stop on the map with this stopId,
                // so check if this is the last line needing it and if so
                // remove it. If not, decrement the counter.
                NSNumber *curCount = self.routeStopsAnnotationsSelected[stopId];
                if (curCount.integerValue == 1 || curCount.integerValue == 0) {
                    [self.mapView removeAnnotation:stopAnnotation];
                    [self.routeStopsAnnotationsSelected removeObjectForKey:stopId];
                } else {
                    self.routeStopsAnnotationsSelected[stopId] = [NSNumber numberWithInteger:curCount.integerValue - 1];
                }
            }
        }];
    }
}

- (void)clearAllRoutes {
    // Unused as of yet
    [self.selectedRoutes removeAllObjects];
    [self.mapView removeOverlays:self.mapView.overlays];
    // Todo: remove stop annotations
}

#pragma mark - MapKit methods

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyline = (MKPolyline *)overlay;
        NSNumber *routeId = [NSNumber numberWithInteger:polyline.title.integerValue];
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        
        ColorConverter *colorConverter = [[ColorConverter alloc] init];
        renderer.strokeColor = [colorConverter colorWithHexString:self.allRoutes[routeId][@"ColorHex"]];
        renderer.lineWidth = 2.0f;
        
        return renderer;
    }
    
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isMemberOfClass:[AEStopAnnotation class]]) {
//        NSLog(@"\n********** viewForAnnotation");
        AEStopAnnotation *stopAnnotation = (AEStopAnnotation *)annotation;
        NSNumber *stopId = stopAnnotation.stopId;
//        NSLog(@"stopId: %@", stopId);
        NSArray *routeIdsForThisStop = [self routeIdsForStopId:stopId];
//        NSLog(@"All routes for this stop: %@", routeIdsForThisStop);
        NSMutableArray *colors = [NSMutableArray array];
        ColorConverter *colorconverter = [[ColorConverter alloc] init];
//        NSLog(@"SelectedRoutes: %@", self.selectedRoutes);
        for (NSNumber *curRouteId in routeIdsForThisStop) {
            if ([self.selectedRoutes containsObject:curRouteId] == true) {
                [colors addObject:[colorconverter colorWithHexString:self.allRoutes[curRouteId][@"ColorHex"]]];
            }
        };
        static NSString* identifier = @"Pin";
        
        AEStopAnnotationView *stopAnnView = (AEStopAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (stopAnnView == nil) {
            stopAnnView = [[AEStopAnnotationView alloc] initWithAnnotation:stopAnnotation reuseIdentifier:identifier];
        } else {
            stopAnnView.annotation = stopAnnotation;
        }
        
        stopAnnView.colors = colors;
        
        stopAnnView.enabled = YES;
        stopAnnView.canShowCallout = YES;
        
        return stopAnnView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(nonnull MKUserLocation *)userLocation {
    static dispatch_once_t once;
    dispatch_once(&once, ^() {
        [self zoomToUserLocation];
    });
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        [manager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
        
        // In a second, fire this to go to the users location
//        [self performSelector:@selector(zoomToUserLocation) withObject:nil afterDelay:1.0];
    } else {
        self.mapView.showsUserLocation = NO;
    }
}

- (void)zoomToUserLocation {
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.025;
    mapRegion.span.longitudeDelta = 0.025;
    
    [self.mapView setRegion:mapRegion animated:NO];
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
