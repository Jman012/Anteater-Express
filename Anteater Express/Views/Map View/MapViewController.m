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

// We'll use these for initiating the map's position
#define UCI_LATITUDE 33.6454
#define UCI_LONGITUDE -117.8426

@interface MapViewController ()

@property (nonatomic, strong) IBOutlet UIBarButtonItem *revealButton;
@property (atomic, strong) IBOutlet MKMapView *mapView;

/* Basic/wholistic route info */
// Holds entire Route dicts, keyed by the route "Id"
@property (nonatomic, strong) NSDictionary<NSNumber*, NSDictionary*> *allRoutes;
// Holds the "Id" for each route, which is used in the allRoutes dict.
@property (nonatomic, strong) NSMutableSet<NSNumber*> *selectedRoutes;
@property (nonatomic, strong) NSMutableSet<NSNumber*> *selectedButAwaitingDataRoutes;
// Holds the route def dicts, keyed by the StopSetId
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, RouteDefinitionDAO*> *routeDefinitions;
// Made from routDefs, holds the MKPolylines by routeId
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, MKPolyline*> *routeDefinitionsPolylines;

/* Route Stop information specifically */
// RouteId -> @[StopSetId], used as a lookup
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSArray<NSNumber*>*> *routeStopsForWhichLines;
// Just holds the MapAnnotation objects. StopId->AEStopAnnotation.
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, AEStopAnnotation*> *routeStopsAnnotationsDict;
// Routes share stops, so this is StopId->count as a retain/release method
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *routeStopsAnnotationsSelected;

// Misc
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation MapViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.name = @"Map View Controller";

        
        // Set up the Location Manager and if we don't already have the authorization,
        // try to request it. If we do have it, already set the mapView to
        // show the users location.
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager requestWhenInUseAuthorization];
        CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
        if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
            authStatus == kCLAuthorizationStatusAuthorizedAlways) {
            [self.locationManager startUpdatingLocation];
            self.mapView.showsUserLocation = YES;
        }
        
        // Initializations
        self.selectedRoutes = [NSMutableSet set];
        self.selectedButAwaitingDataRoutes = [NSMutableSet set];
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
    
    // Setup some complicated gestures so that we can differentiate between moving the map
    // and pulling the side menu out. See also the methods further down under UIGestureRecognizerDelegate
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
    // Start out on Aldrich Park's center. Later it'll move to the users location
    [self zoomToLocation:CLLocationCoordinate2DMake(UCI_LATITUDE, UCI_LONGITUDE)];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupRevealButton {
    // Set up the connections for the hamburger menu button to show the side menu
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
    // Called from the side menu, when the user wants
    // to change to satellite or standard.
    if (newType != self.mapView.mapType) {
        [self.mapView setMapType:newType];
    }
}

#pragma mark - Route Data handling

- (NSArray *)routeIdsForStopId:(NSNumber *)stopId {
    // Given a stopId, return all the routeIDs associated with it.
    // For instance, the bridge stop on the UTC side is a single stop but
    // recieves the orange yellow purple teal and maybe even some other lines. So
    // this would return the routeIds for those colored lines and not the rest.
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
    // Public function to assign current routes.
    // Construct a dict of these where each key is the Id
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSDictionary *routeDict in allRoutesArray) {
        NSNumber *routeId = routeDict[@"Id"];
        dict[routeId] = routeDict;
    }
    self.allRoutes = dict;
}

- (void)setAllRoutes:(NSDictionary *)theAllRoutes {

    _allRoutes = theAllRoutes;
    
    // Now that our routes got set, lets load all the data we need
    // Note: This might be just an update, so we wont be reloading
    // unnecessary data. Only data for routes that we don't have data for.
    // Note: This is assuming we're always getting data when the app opens and isn't
    // subject ot change much. Might add an update date to the data to see if it's too old
    // and download anyway.

    for (NSNumber *routeId in _allRoutes) {
        NSDictionary *routeDict = _allRoutes[routeId];
        NSNumber *routeStopSetId = routeDict[@"StopSetId"];
        
        if (self.routeDefinitions[routeId] == nil) {
            // If our route Definitions (which hold 1. the gps coords and 2. the stops)
            // Then we'll dl it.
            
            [self downloadNewRouteInfoWithId:routeId stopSetId:routeStopSetId];
            
        }
    }
    
    // Now we also should also remove any downloaded data that we don't need anymore.
    // Suppose allRoutes went from @[1,2,3] to @[1,2], we need to get rid of the 3 data.
    
    // First get a set of routeIds from our defs
    NSMutableSet *definedRouteIds = [NSMutableSet set];
    [self.routeDefinitions enumerateKeysAndObjectsUsingBlock:^(NSNumber *routeId, RouteDefinitionDAO *routeDict, BOOL *stop) {
        [definedRouteIds addObject:routeId];
    }];
    NSMutableSet *newRouteIds = [NSMutableSet set];
    [_allRoutes enumerateKeysAndObjectsUsingBlock:^(NSNumber *routeId, NSDictionary *routeDict, BOOL *stop) {
        [newRouteIds addObject:routeId];
    }];
    // Now compare against _allRoutes
    for (NSNumber *routeId in definedRouteIds) {
        if ([newRouteIds containsObject:routeId] == NO) {
            [self.routeDefinitions removeObjectForKey:routeId];
            [self.selectedRoutes removeObject:routeId];
            [self.routeDefinitionsPolylines removeObjectForKey:routeId];
            [self.routeStopsForWhichLines removeObjectForKey:routeId];
        }
    }
}

- (void)downloadNewRouteInfoWithId:(NSNumber *)routeId stopSetId:(NSNumber *)routeStopSetId {
    // Given a routeId, download all the info for it and interpret it
    AEGetRouteDefinition *getRouteOp = [[AEGetRouteDefinition alloc] initWithStopSetId:[routeStopSetId integerValue]];
    getRouteOp.returnBlock = ^(RouteDefinitionDAO *routeDefinition) {
        // Note: This is asynchronous, and possibly out of order
        
        // Set routeDefinitions
        self.routeDefinitions[routeId] = routeDefinition;
        
        
        /* ROUTE LINE */
        // Set routeDefinitionsPolylines for the route line
        NSArray *routePoints = [self.routeDefinitions[routeId] getRoutePoints];
        MKMapPoint *routeMapPointsCArray = malloc(sizeof(MKMapPoint) * routePoints.count);
        // Make C Array
        [routePoints enumerateObjectsUsingBlock:^(NSDictionary *curPointDict, NSUInteger idx, BOOL *stop) {
            CLLocationDegrees latitude  = [[curPointDict objectForKey:@"Latitude"] doubleValue];
            CLLocationDegrees longitude = [[curPointDict objectForKey:@"Longitude"] doubleValue];
            
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            MKMapPoint point = MKMapPointForCoordinate(coordinate);
            routeMapPointsCArray[idx] = point;
            
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
            
            // Set up a helper data structure for ease if finding which stopIds are assigned for each routeId.
            [stopNumbersForTheRoute addObject:curStopDict[@"StopId"]];
            
            // Also, make the Stop Annotations and assign them to the dictionary
            if (self.routeStopsAnnotationsDict[stopId] == nil) {
                // No annotation set, make a new annotation and assign it to this stopId
                AEStopAnnotation *newStopAnnotation = [[AEStopAnnotation alloc] initWithDictionary:[curStopDict copy]];
                self.routeStopsAnnotationsDict[stopId] = newStopAnnotation;
            } else {
                // There exists an annotation, so just add the dict to it.
                AEStopAnnotation *stopAnnotation = self.routeStopsAnnotationsDict[stopId];
                [stopAnnotation addNewDictionary:curStopDict];
            }
        }];
        self.routeStopsForWhichLines[routeId] = stopNumbersForTheRoute;
        
        // Finally, check to see if the the route was awaiting all this data and if so re-add
        if ([self.selectedButAwaitingDataRoutes containsObject:routeId]) {
            [self.selectedButAwaitingDataRoutes removeObject:routeId];
            [self showNewRoute:routeId];
        }
        
        // And to be safe, reload all the annotations currently on screen.
        NSArray *annotations = self.mapView.annotations;
        [self.mapView removeAnnotations:annotations];
        [self.mapView addAnnotations:annotations];
    };
    [self.operationQueue addOperation:getRouteOp];
}

#pragma mark - Route selection methods

- (void)showNewRoute:(NSNumber *)theId {
    NSLog(@"Showing new route: %@", theId);
    
    if (self.routeDefinitionsPolylines[theId] == nil) {
        // The route was selected but we don't have the info for it just yet.
        // Store the id in another data structure so when the data arrives it'll know to
        // call this again
        [self.selectedButAwaitingDataRoutes addObject:theId];
        return;
    }
    
    // Else, proceed as normal
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
    if ([self.selectedButAwaitingDataRoutes containsObject:theId]) {
        // If it's in the queue awaiting to be added, remove it.
        [self.selectedButAwaitingDataRoutes removeObject:theId];
    }
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
                    
                    // Don't forget to refresh the colors on the color wheel
                    [self.mapView removeAnnotation:stopAnnotation];
                    [self.mapView addAnnotation:stopAnnotation];
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
    // Called for the route polylines
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyline = (MKPolyline *)overlay;
        NSNumber *routeId = [NSNumber numberWithInteger:polyline.title.integerValue];
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        
        renderer.strokeColor = [ColorConverter colorWithHexString:self.allRoutes[routeId][@"ColorHex"]];
        if (self.selectedRoutes.count > 1) {
            // If it's the second or third or so on line being added, do half alpha as a way
            // to better differentiate overlapping lines. This is how the website currently
            // does it, from what I saw.
            renderer.strokeColor = [renderer.strokeColor colorWithAlphaComponent:0.5];
        }
        renderer.lineWidth = 2.0f;
        
        return renderer;
    }
    
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // This is called for route Stops and Vehicles. Currently undefined for Vehicles.
    if ([annotation isMemberOfClass:[AEStopAnnotation class]]) {

        // Setup information needed for later
        static NSString* identifier = @"Pin";
        AEStopAnnotation *stopAnnotation = (AEStopAnnotation *)annotation;
        NSNumber *stopId = stopAnnotation.stopId;
        NSArray *routeIdsForThisStop = [self routeIdsForStopId:stopId];
        // Construct colors array from the selected lines, to be passed to the view
        NSMutableArray *colors = [NSMutableArray array];
        for (NSNumber *curRouteId in routeIdsForThisStop) {
            if ([self.selectedRoutes containsObject:curRouteId] == true) {
                [colors addObject:[ColorConverter colorWithHexString:self.allRoutes[curRouteId][@"ColorHex"]]];
            }
        };
        
        // Make the stop view
        AEStopAnnotationView *stopAnnView = (AEStopAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (stopAnnView == nil) {
            // Nothing dequeued, make a new one. This should only happen a few times.
            stopAnnView = [[AEStopAnnotationView alloc] initWithAnnotation:stopAnnotation reuseIdentifier:identifier];
            stopAnnView.enabled = YES;
            stopAnnView.canShowCallout = YES;
        } else {
            // Dequeued, make sure to change the stopAnnotation assigned to it.
            stopAnnView.annotation = stopAnnotation;
        }
        
        // Then either way, make sure the colors get assigned
        stopAnnView.colors = colors;
        
        return stopAnnView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(nonnull MKUserLocation *)userLocation {
    // Only do this once, when we first get the user's location. We don't want it
    // tracking them on every movement.
    static dispatch_once_t once;
    dispatch_once(&once, ^() {
        [self zoomToLocation:userLocation.coordinate];
    });
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        // We became authorized
        [manager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
    } else {
        // We still aren't authorized or we changed to unauthorized
        self.mapView.showsUserLocation = NO;
    }
}

- (void)zoomToLocation:(CLLocationCoordinate2D)coordinate {
    MKCoordinateRegion mapRegion;
    mapRegion.center = coordinate;
    mapRegion.span.latitudeDelta = 0.025;
    mapRegion.span.longitudeDelta = 0.025;
    
    [self.mapView setRegion:mapRegion animated:NO];
}

#pragma mark - SWRevealViewController

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position {
    // When the side menu is being shown, deisable user interaction on the map so that
    // They can't move it around, and the whole of it can be used to drag the side
    // menu closed.
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
    
    // If the touch began in the leftmost 30 points, fail so that the reveal pan can work.
    return self.mapView.userInteractionEnabled && CGRectContainsPoint(boundingRect, location);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
