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

#import "AppDelegate.h"

#import "AEGetRouteDefinition.h"
#import "AEGetVehiclesOp.h"
#import "AEGetArrivalPredictionsOp.h"
#import "ColorConverter.h"
#import "AENetwork.h"

#import "AEStopAnnotation.h"
#import "AEVehicleAnnotation.h"
#import "AEStopAnnotationView.h"
#import "AEVehicleAnnotationView.h"
#import "ArrivalPredictionView.h"

// We'll use these for initiating the map's position
#define UCI_LATITUDE 33.6454
#define UCI_LONGITUDE -117.8426
#define UCI_RADIUS 6500

#define MAP_POINT_PADDING 1000
#define MAP_LENGTH_PADDING (MAP_POINT_PADDING * 2)

@interface MapViewController ()

@property (nonatomic, strong) IBOutlet UIBarButtonItem *revealButton;
@property (nonatomic, strong) IBOutlet ASMapView *mapView;

/* Basic/wholistic route info */
// Holds entire Route dicts, keyed by the RouteId
@property (nonatomic, strong) NSDictionary<NSNumber*, NSDictionary*> *allRoutes;
// Holds the RouteId for each route for currently selected routes, which is used in the allRoutes dict.
@property (nonatomic, strong) NSMutableSet<NSNumber*> *selectedRoutes;
// If we tried selecting a route but we don't have the RouteDefinition yet, place it in here
@property (nonatomic, strong) NSMutableSet<NSNumber*> *selectedButAwaitingDataRoutes;
// Holds the route def dicts, keyed by the RouteId
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, RouteDefinitionDAO*> *routeDefinitions;
// Made from routDefs, holds the MKPolylines by RouteId
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, MKPolyline*> *routeDefinitionsPolylines;
// Set of routeIds that represent which lines are currently being downloaded, so we don't do double
@property (nonatomic, strong) NSMutableSet<NSNumber*> *downloadingDefinitions;

/* Route Stop information specifically */
// RouteId -> @[StopSetId], used as a lookup
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSArray<NSNumber*>*> *routeStopsForWhichLines;
// StopSetId -> RouteId
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *routeIdForStopSetId;
// Just holds the MapAnnotation objects. StopId->AEStopAnnotation.
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, AEStopAnnotation*> *routeStopsAnnotationsDict;
// Routes share stops, so this is StopId->count as a retain/release method
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *routeStopsAnnotationsSelected;

/* Route Vehicle Centric stuff */
@property (nonatomic, strong) NSTimer *vehicleUpdateTimer;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,AEVehicleAnnotation*> *vehicleAnnotationsForVehicleId;

// Misc
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) MKUserLocation *userLocation;

@property (nonatomic, assign) MKMapPoint northEastPoint;
@property (nonatomic, assign) MKMapPoint southWestPoint;
@property (nonatomic, assign) BOOL pointsSet;
@property (nonatomic, assign) dispatch_once_t mapSetOnce;

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
        self.routeIdForStopSetId = [NSMutableDictionary dictionary];
        self.downloadingDefinitions = [NSMutableSet set];
        self.vehicleAnnotationsForVehicleId = [NSMutableDictionary dictionary];
        
        self.pointsSet = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.screenName = [NSString stringWithFormat:@"Main Map View - %lu routes", (unsigned long)self.selectedRoutes.count];
    
    [self setupRevealButton];
    
    // Title with image
    UIImage *titleImg = [UIImage imageNamed:@"AnteaterExpress_logo_title"];
    CGFloat widthToHeightRatio = titleImg.size.width / titleImg.size.height;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Anteater Express";
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textColor = [UIColor blackColor];
    [titleLabel sizeToFit];
    
    CGFloat titleHeight = titleLabel.frame.size.height;
    CGFloat imageHeight = titleHeight;
    CGFloat imageWidth = titleHeight * widthToHeightRatio;
    
    titleLabel.frame = CGRectMake(imageWidth + 8, 0, titleLabel.frame.size.width, titleHeight);
    
    
    UIImageView *titleImage = [[UIImageView alloc] initWithImage:titleImg];
    titleImage.frame = CGRectMake(0, 0, imageWidth, imageHeight);
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, titleLabel.frame.size.width + imageWidth + 8, titleHeight)];
    [titleView addSubview:titleLabel];
    [titleView addSubview:titleImage];
    self.navigationItem.titleView = titleView;
    
    // Setup some complicated gestures so that we can differentiate between moving the map
    // and pulling the side menu out. See also the methods further down under UIGestureRecognizerDelegate
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
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    // Start out on Aldrich Park's center. Later it'll move to the users location
//    [self zoomToLocation:CLLocationCoordinate2DMake(UCI_LATITUDE, UCI_LONGITUDE)];
    dispatch_once_t once = self.mapSetOnce;
    dispatch_once(&once, ^() {
        CLLocation *uciLocation = [[CLLocation alloc] initWithLatitude:UCI_LATITUDE longitude:UCI_LONGITUDE];
        [self zoomToLocation:uciLocation.coordinate];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkResponse:) name:AENetworkInternetError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkResponse:) name:AENetworkServerError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkResponse:) name:AENetworkOk object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [self startTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // So if another view is pushed, don't swipe to the side menu.
    [self.navigationController.view removeGestureRecognizer:self.revealViewController.panGestureRecognizer];
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

- (void)setMapType:(MKMapType)newType {
    // Called from the side menu, when the user wants
    // to change to satellite or standard.
    if (newType != self.mapView.mapType) {
        [self.mapView setMapType:newType];
    }
}

- (void)networkResponse:(NSNotification *)sender {
    if ([sender.object isKindOfClass:[NSString class]]) {
        NSString *senderString = (NSString *)sender.object;
        if ([senderString isEqualToString:AENetworkInternetError]) {
            [TSMessage showNotificationInViewController:self
                                                  title:@"Bad Internet Connection"
                                               subtitle:@"Check to see if your phone has WiFi internet access or your cellular connection is working."
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSMessageNotificationDurationEndless
                                               callback:nil
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        } else if ([senderString isEqualToString:AENetworkServerError]) {
            [TSMessage showNotificationInViewController:self
                                                  title:@"Anteater Express Servers Down"
                                               subtitle:@"Could not contact the Anteater Express servers to get the necessary information."
                                                  image:nil
                                                   type:TSMessageNotificationTypeError
                                               duration:TSMessageNotificationDurationEndless
                                               callback:nil
                                            buttonTitle:nil
                                         buttonCallback:nil
                                             atPosition:TSMessageNotificationPositionTop
                                   canBeDismissedByUser:YES];
        } else if ([senderString isEqualToString:AENetworkOk]) {
            [TSMessage dismissActiveNotification];
        }
    }
}

- (void)applicationWillResignActive:(NSNotification *)sender {
    // Invalidate the vehicle timer
    [self endTimer];
    
    // Remove all vehicles from the view
    [self.mapView.annotations enumerateObjectsUsingBlock:^(id<MKAnnotation> annotation, NSUInteger idx, BOOL *stop) {
        if ([annotation isMemberOfClass:[AEVehicleAnnotation class]]) {
            AEVehicleAnnotation *vehicleAnnotation = (AEVehicleAnnotation *)annotation;
            [self.mapView removeAnnotation:vehicleAnnotation];
            [self.vehicleAnnotationsForVehicleId removeObjectForKey:vehicleAnnotation.vehicleId];
        }
    }];
}

- (void)applicationDidBecomeActive:(NSNotification *)sender {
    // Now also initiate the timer to update vehicle positions
    [self startTimer];

    [self showClosestAnnotation];
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

- (BOOL)stopSetIdInSelected:(NSNumber *)stopSetId {
    __block BOOL ret = false;
    [self.selectedRoutes enumerateObjectsUsingBlock:^(NSNumber *routeId, BOOL *stop) {
        NSNumber *selectedStopSetId = self.allRoutes[routeId][@"StopSetId"];
        if ([selectedStopSetId isEqualToNumber:stopSetId]) {
            ret = true;
            *stop = true;
        }
    }];
    return ret;
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
        
        if (self.routeDefinitions[routeId] == nil && [self.downloadingDefinitions containsObject:routeId] == false) {
            // If our route Definitions (which hold 1. the gps coords and 2. the stops)
            // Then we'll dl it.
            
            [self downloadNewRouteInfoWithId:routeId stopSetId:routeStopSetId];
            [self.downloadingDefinitions addObject:routeId];
            
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
    
    if (routeId == nil || routeStopSetId == nil) {
        return;
    }
    
    // Given a routeId, download all the info for it and interpret it
    AEGetRouteDefinition *getRouteOp = [[AEGetRouteDefinition alloc] initWithStopSetId:[routeStopSetId integerValue]];
    getRouteOp.returnBlock = ^(RouteDefinitionDAO *routeDefinition) {
        // Note: This is asynchronous, and possibly out of order
        
        if (routeDefinition == nil || [routeDefinition getRoutePoints] == nil || [routeDefinition getRouteStops] == nil) {
            // No data from the network
            return;
        }
        
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
        
        // At this point, if we're updating instead of just inserting, we
        // need to make sure there are no lost references in the mapView
        BOOL readd = NO;
        if (self.routeDefinitionsPolylines[routeId] != nil &&
            [self.mapView.overlays containsObject:self.routeDefinitionsPolylines[routeId]]) {
            [self.mapView removeOverlay:self.routeDefinitionsPolylines[routeId]];
            readd = YES;
        }
        self.routeDefinitionsPolylines[routeId] = polyline;
        if (readd == YES) {
            [self.mapView addOverlay:self.routeDefinitionsPolylines[routeId]];
            readd = NO;
        }
        
        
        /* ROUTE STOPS */
        NSNumber *stopSetId = self.allRoutes[routeId][@"StopSetId"];
        self.routeIdForStopSetId[stopSetId] = routeId;
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
        
        // Finally represent that we're no longer downloading this definition
        [self.downloadingDefinitions removeObject:routeId];
        if (self.downloadingDefinitions.count == 0) {
            [self downloadingRouteInfoDidFinish];
        }
    };
    [self.operationQueue addOperation:getRouteOp];
}

- (void)downloadingRouteInfoDidFinish {
    // Called when the self.downloadingDefinitions.count == 0
    if (self.userLocation != nil) {
        [self showClosestAnnotation];
    }
}

- (void)showClosestAnnotation {
    if (self.mapView.annotations.count == 0) {
        return;
    }
    
    NSArray *sortedAnnotationsByProximity = [self.mapView.annotations sortedArrayUsingComparator:^NSComparisonResult(NSObject<MKAnnotation> *a, NSObject<MKAnnotation> *b) {
        CLLocation *locationA = [[CLLocation alloc] initWithLatitude:a.coordinate.latitude longitude:a.coordinate.longitude];
        CLLocation *locationB = [[CLLocation alloc] initWithLatitude:b.coordinate.latitude longitude:b.coordinate.longitude];
        CLLocationDistance distanceA = [locationA distanceFromLocation:self.userLocation.location];
        CLLocationDistance distanceB = [locationB distanceFromLocation:self.userLocation.location];
        
        if (distanceA > distanceB) {
            return NSOrderedDescending;
        } else if (distanceB > distanceA) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    [sortedAnnotationsByProximity enumerateObjectsUsingBlock:^(NSObject<MKAnnotation> *annotation, NSUInteger idx, BOOL *stop) {
        if ([annotation isMemberOfClass:[AEStopAnnotation class]]) {
            [self.mapView selectAnnotation:annotation animated:YES];
            *stop = true;
        }
    }];

}

#pragma mark - Vehicle Data Handling and Updating

- (void)startTimer {
    if (self.vehicleUpdateTimer == nil || self.vehicleUpdateTimer.valid == NO) {
        self.vehicleUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                   target:self
                                                                 selector:@selector(updateAllVehiclesForSelectedRoutes:)
                                                                 userInfo:nil
                                                                  repeats:YES];
        [self updateAllVehiclesForSelectedRoutes:self.vehicleUpdateTimer];
    }
}

- (void)endTimer {
    if (self.vehicleUpdateTimer != nil) {
        [self.vehicleUpdateTimer invalidate];
    }
}

- (void)updateAllVehiclesForSelectedRoutes:(NSTimer *)timer {
    [self.selectedRoutes enumerateObjectsUsingBlock:^(NSNumber *routeId, BOOL *stop) {
        [self downloadNewVehicleInfoWithStopSetId:self.allRoutes[routeId][@"StopSetId"] routeId:routeId];
    }];
    
    // Also, if routes have yet to be downloaded, download them!
    for (NSNumber *routeId in self.selectedButAwaitingDataRoutes) {
        NSNumber *stopSetId = self.allRoutes[routeId][@"StopSetId"];
        NSLog(@"Retrying download route id %@, stop set id %@", routeId, stopSetId);
        [self downloadNewRouteInfoWithId:routeId stopSetId:stopSetId];
    }
}

- (void)downloadNewVehicleInfoWithStopSetId:(NSNumber *)stopSetId routeId:(NSNumber *)routeId {
    AEGetVehiclesOp *getVehiclesOperation = [[AEGetVehiclesOp alloc] initWithStopSetId:stopSetId.integerValue];
    getVehiclesOperation.returnBlock = ^(RouteVehiclesDAO *routeVehiclesDAO) {
        
        [[routeVehiclesDAO getRouteVehicles] enumerateObjectsUsingBlock:^(NSDictionary *vehicleDict, NSUInteger idx, BOOL *stop) {
            NSNumber *vehicleId = vehicleDict[@"ID"];
            if (self.vehicleAnnotationsForVehicleId[vehicleId] == nil) {
                // Not yet set
                AEVehicleAnnotation *vehicleAnnotation = [[AEVehicleAnnotation alloc] initWithVehicleDictionary:vehicleDict routeDict:self.allRoutes[routeId]];
                vehicleAnnotation.stopSetId = stopSetId;
                [self.mapView addAnnotation:vehicleAnnotation];
                self.vehicleAnnotationsForVehicleId[vehicleId] = vehicleAnnotation;
            } else {
                // Already exists
                AEVehicleAnnotation *vehicleAnnotation = self.vehicleAnnotationsForVehicleId[vehicleId];
                vehicleAnnotation.vehicleDictionary = vehicleDict;
                
                // Then try to update the view
                AEVehicleAnnotationView *vehicleAnnotationView = (AEVehicleAnnotationView *)[self.mapView viewForAnnotation:vehicleAnnotation];
                vehicleAnnotationView.tintColor = [ColorConverter colorWithHexString:self.allRoutes[routeId][@"ColorHex"]];
                [vehicleAnnotationView setVehicleImage:vehicleAnnotation.vehiclePicture];
            }
        }];
        
    };
    [self.operationQueue addOperation:getVehiclesOperation];
}

#pragma mark - Route selection methods

- (void)showNewRoute:(NSNumber *)theId {
    
    if (self.routeDefinitionsPolylines[theId] == nil) {
        // The route was selected but we don't have the info for it just yet.
        // Store the id in another data structure so when the data arrives it'll know to
        // call this again
        [self.selectedButAwaitingDataRoutes addObject:theId];
        NSLog(@"Queueing new route to be shown: %@", theId);
        return;
    }
    NSLog(@"Showing new route: %@", theId);

    
    // Else, proceed as normal
    [self.selectedRoutes addObject:theId];
    self.screenName = [NSString stringWithFormat:@"Main Map View - %lu routes", (unsigned long)self.selectedRoutes.count];
    
    // Add the route lines to the map
    if (self.routeDefinitionsPolylines[theId] != nil) {
        [self.mapView addOverlay:self.routeDefinitionsPolylines[theId]];
        
        MKPolyline *polyline = self.routeDefinitionsPolylines[theId];
        MKMapPoint northEastPoint = self.northEastPoint;
        MKMapPoint southWestPoint = self.southWestPoint;
        for (int i = 0; i < polyline.pointCount; ++i) {
            MKMapPoint point = polyline.points[i];
            
            if (self.pointsSet == NO) {
                northEastPoint = point;
                southWestPoint = point;
                self.pointsSet = YES;
            }
            else
            {
                if (point.x > northEastPoint.x)
                    northEastPoint.x = point.x;
                if(point.y > northEastPoint.y)
                    northEastPoint.y = point.y;
                if (point.x < southWestPoint.x)
                    southWestPoint.x = point.x;
                if (point.y < southWestPoint.y) 
                    southWestPoint.y = point.y;
            }
        }
        self.northEastPoint = northEastPoint;
        self.southWestPoint = southWestPoint;
        MKMapRect routeRect = MKMapRectMake(self.southWestPoint.x - MAP_POINT_PADDING, self.southWestPoint.y - MAP_POINT_PADDING, self.northEastPoint.x - self.self.southWestPoint.x + MAP_LENGTH_PADDING, self.northEastPoint.y - self.southWestPoint.y + MAP_LENGTH_PADDING);
        
        dispatch_once_t once = self.mapSetOnce;
        dispatch_once(&once, ^() {
            CLLocation *uciLocation = [[CLLocation alloc] initWithLatitude:UCI_LATITUDE longitude:UCI_LONGITUDE];
            [self zoomToLocation:uciLocation.coordinate];
        });
        [self.mapView setVisibleMapRect:routeRect animated:NO];
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
    
    // Manually invoke the vehicles to be downloaded
    [self downloadNewVehicleInfoWithStopSetId:self.allRoutes[theId][@"StopSetId"] routeId:theId];
}

- (void)removeRoute:(NSNumber *)theId {
    NSLog(@"Removing route: %@", theId);
    if ([self.selectedButAwaitingDataRoutes containsObject:theId]) {
        // If it's in the queue awaiting to be added, remove it.
        [self.selectedButAwaitingDataRoutes removeObject:theId];
    }
    
    [self.selectedRoutes removeObject:theId];
    self.screenName = [NSString stringWithFormat:@"Main Map View - %lu routes", (unsigned long)self.selectedRoutes.count];
    
    // Remove the route line
    if (self.routeDefinitionsPolylines[theId] != nil) {
        [self.mapView removeOverlay:self.routeDefinitionsPolylines[theId]];
        
        self.pointsSet = NO;
        for (id<MKOverlay> overlay in self.mapView.overlays) {
            if ([overlay isMemberOfClass:[MKPolyline class]] == NO) {
                continue;
            }
            
            MKPolyline *polyline = (MKPolyline *)overlay;
            MKMapPoint northEastPoint = self.northEastPoint;
            MKMapPoint southWestPoint = self.southWestPoint;
            for (int i = 0; i < polyline.pointCount; ++i) {
                MKMapPoint point = polyline.points[i];
                
                if (self.pointsSet == NO) {
                    northEastPoint = point;
                    southWestPoint = point;
                    self.pointsSet = YES;
                }
                else
                {
                    if (point.x > northEastPoint.x)
                        northEastPoint.x = point.x;
                    if(point.y > northEastPoint.y)
                        northEastPoint.y = point.y;
                    if (point.x < southWestPoint.x)
                        southWestPoint.x = point.x;
                    if (point.y < southWestPoint.y)
                        southWestPoint.y = point.y;
                }
            }
            self.northEastPoint = northEastPoint;
            self.southWestPoint = southWestPoint;
        }
        MKMapRect routeRect = MKMapRectMake(self.southWestPoint.x - MAP_POINT_PADDING, self.southWestPoint.y - MAP_POINT_PADDING, self.northEastPoint.x - self.self.southWestPoint.x + MAP_LENGTH_PADDING, self.northEastPoint.y - self.southWestPoint.y + MAP_LENGTH_PADDING);
        
        dispatch_once_t once = self.mapSetOnce;
        dispatch_once(&once, ^() {
            CLLocation *uciLocation = [[CLLocation alloc] initWithLatitude:UCI_LATITUDE longitude:UCI_LONGITUDE];
            [self zoomToLocation:uciLocation.coordinate];
        });
        [self.mapView setVisibleMapRect:routeRect animated:NO];
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
    
    // Remove the route buses
    NSNumber *stopSetId = self.allRoutes[theId][@"StopSetId"];
    [self.mapView.annotations enumerateObjectsUsingBlock:^(id<MKAnnotation> annotation, NSUInteger idx, BOOL *stop) {
        if ([annotation isMemberOfClass:[AEVehicleAnnotation class]]) {
            AEVehicleAnnotation *vehicleAnnotation = (AEVehicleAnnotation *)annotation;
            if ([vehicleAnnotation.stopSetId isEqualToNumber:stopSetId]) {
                [self.vehicleAnnotationsForVehicleId removeObjectForKey:vehicleAnnotation.vehicleId];
                [self.mapView removeAnnotation:vehicleAnnotation];
            }
        }
    }];
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
            renderer.strokeColor = [renderer.strokeColor colorWithAlphaComponent:0.75];
        }
        renderer.lineWidth = 2.5f;
        
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
    } else if ([annotation isMemberOfClass:[AEVehicleAnnotation class]]) {
        static NSString *vehicleIdentifier = @"Vehicle";
        AEVehicleAnnotation *vehicleAnnotation = (AEVehicleAnnotation *)annotation;
        
        AEVehicleAnnotationView *vehicleAnnotationView = (AEVehicleAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:vehicleIdentifier];
        if (vehicleAnnotationView == nil) {
            vehicleAnnotationView = [[AEVehicleAnnotationView alloc] initWithAnnotation:vehicleAnnotation reuseIdentifier:vehicleIdentifier];
            vehicleAnnotationView.enabled = YES;
            vehicleAnnotationView.canShowCallout = YES;
        } else {
            vehicleAnnotationView.annotation = vehicleAnnotation;
        }
        
        // Set Image
        NSNumber *routeId = vehicleAnnotation.routeDictionary[@"Id"];
        vehicleAnnotationView.tintColor = [ColorConverter colorWithHexString:self.allRoutes[routeId][@"ColorHex"]];
        [vehicleAnnotationView setVehicleImage:vehicleAnnotation.vehiclePicture];
        
        return vehicleAnnotationView;
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(nonnull NSArray<MKAnnotationView *> *)views {
    for (MKAnnotationView *view in views) {
        if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
            MKAnnotationView *userLocView = (MKAnnotationView *)view;
            userLocView.canShowCallout = NO;
        }
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(nonnull MKUserLocation *)userLocation {
    // Only do this once, when we first get the user's location. We don't want it
    // tracking them on every movement.
//    static dispatch_once_t once;
//    dispatch_once(&once, ^() {
//        CLLocation *uciLocation = [[CLLocation alloc] initWithLatitude:UCI_LATITUDE longitude:UCI_LONGITUDE];
//        if ([uciLocation distanceFromLocation:userLocation.location] < UCI_RADIUS) {
//            [self zoomToLocation:userLocation.coordinate];
//            self.userLocation = userLocation;
//            if (self.downloadingDefinitions.count == 0) {
//                [self showClosestAnnotation];
//            }
//        }
//    });
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view isMemberOfClass:[AEStopAnnotationView class]]) {

        AEStopAnnotation *stopAnnotaton = (AEStopAnnotation *)view.annotation;
        stopAnnotaton.arrivalPredictions = [NSMutableDictionary dictionary]; // Reset predictions
        
        // Go through all stopSetIds assigned to this stop annotation
        __block NSMutableArray *stopSetIds = [NSMutableArray array];
        __block NSMutableArray *stopIds = [NSMutableArray array];
        [stopAnnotaton.stopSetIds enumerateObjectsUsingBlock:^(NSNumber *stopSetId, NSUInteger idx, BOOL *stop) {
            if ([self stopSetIdInSelected:stopSetId] == false) {
                // Only download/show predictions for lines that are selected
                return;
            }
            [stopSetIds addObject:stopSetId];
            [stopIds addObject:stopAnnotaton.stopId];
        }];
        
        // Download the predictions for this stopSetId/stopId combo
        AEGetArrivalPredictionsOp *arrivalPredictionsOp = [[AEGetArrivalPredictionsOp alloc] initWithStopSetIds:stopSetIds stopIds:stopIds];
        arrivalPredictionsOp.returnBlock = ^(NSArray<StopArrivalPredictionDAO *> *stopArrivalPredictionsDAOs) {
            // Here we're done downloading all the arrival predictions
            
            // First go through and add all the predictions into the annotation
            // regardless of subtitle or stack view usage
            [stopArrivalPredictionsDAOs enumerateObjectsUsingBlock:^(StopArrivalPredictionDAO *stopArrivalPredictionsDAO, NSUInteger idx, BOOL *stop) {
                [stopAnnotaton willChangeValueForKey:@"subtitle"];
                stopAnnotaton.arrivalPredictions[stopSetIds[idx]] = [stopArrivalPredictionsDAO.getArrivalTimes valueForKey:@"Predictions"];
                [stopAnnotaton didChangeValueForKey:@"subtitle"];
            }];
            
            // Make sure we can handle stack views and detail callout views
            if (!NSClassFromString(@"UIStackView") || ![view respondsToSelector:@selector(detailCalloutAccessoryView)]) {
                // If not we've done all we can
                return;
            }
            
            UIView *container = [[UIView alloc] init];
            
            // Otherwise, we're good. Make the stack view and put it in a container
            __block UIStackView *stackView = [[UIStackView alloc] init];
            stackView.axis = UILayoutConstraintAxisVertical;
            stackView.distribution = UIStackViewDistributionEqualSpacing;
            stackView.alignment = UIStackViewAlignmentLeading;
            stackView.spacing = 4;
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            [container addSubview:stackView];
            
            /*
            // And add a manual subtitle label for above the stack view
            UILabel *subtitleLabel = [[UILabel alloc] init];
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
            subtitleLabel.text = @"Text subtitle";
            subtitleLabel.font = [subtitleLabel.font fontWithSize:10.0f];
            [subtitleLabel sizeToFit];
            [container addSubview:subtitleLabel];
            NSLog(@"subtitle label height = %f", subtitleLabel.frame.size.height);
            
            
            // Label height
            [container addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:subtitleLabel.frame.size.height]];
            
            // Label left and right
            [container addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
            [container addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
            
            // Stackview left and right
            [container addConstraint:[NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
            [container addConstraint:[NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
            
            // Label top to container top
            [container addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
            // Label bottom to stackview top
            [container addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:stackView attribute:NSLayoutAttributeTop multiplier:1.0 constant:4]];
            // Stackview bottom to container bottom
            [container addConstraint:[NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
             */
        
            // Then populate the stack view
            [stopArrivalPredictionsDAOs enumerateObjectsUsingBlock:^(StopArrivalPredictionDAO *stopArrivalPredictionsDAO, NSUInteger idx, BOOL *stop) {
                // Vars
                NSNumber *stopSetId = stopSetIds[idx];
                NSNumber *routeId = self.routeIdForStopSetId[stopSetId];
                
                // If iOS9, use a stack view to show the times

                // Add the custom view, assigning the info
                NSArray *elements = [[NSBundle mainBundle] loadNibNamed:@"ArrivalPredictionView" owner:self options:nil];
                ArrivalPredictionView *arrivalsView = [elements firstObject];
                // Use the annotation to make the text for us
                arrivalsView.textLabel.text = [stopAnnotaton formattedSubtitleForStopSetId:stopSetId abbreviation:self.allRoutes[routeId][@"Abbreviation"]];
                arrivalsView.colorView.backgroundColor = [ColorConverter colorWithHexString:self.allRoutes[routeId][@"ColorHex"]];

                
                [stackView addArrangedSubview:arrivalsView];
                
            }];
        
            view.detailCalloutAccessoryView = stackView;
//            view.detailCalloutAccessoryView = container;
        };
        [self.operationQueue addOperation:arrivalPredictionsOp];
        
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(nonnull MKAnnotationView *)view {
    if ([view respondsToSelector:@selector(detailCalloutAccessoryView)]) {
        view.detailCalloutAccessoryView = nil;
    }
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
