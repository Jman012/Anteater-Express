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
#import "RouteDetailViewController.h"

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
@property (nonatomic, strong) IBOutlet UIButton *locationButton;

@property (nonatomic, strong) UIImage *locationButtonBusImage;
@property (nonatomic, strong) UIImage *locationButtonLocationImage;
@property (nonatomic, assign) BOOL showingLocationImage;

/* Basic/wholistic route info */
// Made from routDefs, holds the MKPolylines by RouteId
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, MKPolyline*> *routeDefinitionsPolylines;

/* Route Stop information specifically */
// Just holds the MapAnnotation objects. StopId->AEStopAnnotation.
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, AEStopAnnotation*> *stopAnnotationForStopId;
// Routes share stops, so this is StopId->count as a retain/release method
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *routeStopsAnnotationsSelected;
@property (nonatomic, weak) MKAnnotationView *selectedStopAnnotationView;

/* Route Vehicle Centric stuff */
// Route Id -> (Vehicle Id -> Annotation)
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSMutableDictionary*> *vehicleForRouteAndVehicleId;

// Misc
//@property (nonatomic, strong) NSOperationQueue *operationQueue;
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
        self.routeDefinitionsPolylines = [NSMutableDictionary dictionary];
        self.stopAnnotationForStopId = [NSMutableDictionary dictionary];
        self.routeStopsAnnotationsSelected = [NSMutableDictionary dictionary];
        self.vehicleForRouteAndVehicleId = [NSMutableDictionary dictionary];
        
        self.pointsSet = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"Map setting delegate");
    [AEDataModel.shared addDelegate:self];
    
    // Do any additional setup after loading the view.
    
    
    [self setupRevealButton];
    
    self.locationButtonBusImage = [[UIImage imageNamed:@"shuttle_E_moving"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.locationButtonLocationImage = [[UIImage imageNamed:@"Location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.locationButton setImage:self.locationButtonBusImage forState:UIControlStateNormal];
    self.locationButton.imageView.tintColor = self.view.tintColor;
    self.locationButton.layer.cornerRadius = 16.0;
    self.locationButton.layer.masksToBounds = false;
    self.locationButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.locationButton.layer.shadowOffset = CGSizeMake(0.0, 0.5);
    self.locationButton.layer.shadowRadius = 1.0;
    self.locationButton.layer.shadowOpacity = 0.5;

    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    blurView.frame = self.locationButton.bounds;
    blurView.userInteractionEnabled = false;
    blurView.clipsToBounds = true;
    blurView.layer.cornerRadius = 16.0;
    [self.locationButton insertSubview:blurView atIndex:0];
    self.locationButton.backgroundColor = [UIColor clearColor];
    
    
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
    
    [self zoomToLocation:CLLocationCoordinate2DMake(UCI_LATITUDE, UCI_LONGITUDE) animated:false userLoc:false];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

    
    for (NSNumber *routeId in AEDataModel.shared.selectedRoutes) {
        [self aeDataModel:AEDataModel.shared didSelectRoute:routeId];
    }

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self resetMapRect:false];
    
    [self.navigationController.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
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

- (void)resetScreenName {
    self.screenName = [NSString stringWithFormat:@"Main Map View - %lu routes", (unsigned long)AEDataModel.shared.selectedRoutes.count];
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

- (void)applicationDidBecomeActive:(NSNotification *)sender {

    [self showClosestAnnotation];
}

- (IBAction)locationButtonTouched:(UIButton *)sender {
    if (self.showingLocationImage) {
        [self zoomToLocation:self.userLocation.location.coordinate animated:true userLoc:true];
        
        [self.locationButton setImage:self.locationButtonBusImage forState:UIControlStateNormal];
        self.showingLocationImage = false;
    } else {
        [self resetMapRect:true];
    }
}

#pragma mark - Route Data handling

- (void)aeDataModel:(AEDataModel *)aeDataModel didSelectRoute:(NSNumber *)routeId {
    [self resetScreenName];
    
    Route *route = [aeDataModel routeForId:routeId];
    if ([aeDataModel vehiclesForRouteId:routeId] != nil) {
//        [self refreshVehicles:[aeDataModel vehiclesForRouteId:routeId] forRoute:route];
    }
    
    if ([aeDataModel wayPointsForRouteId:routeId] != nil) {
        [self addWaypoints:[aeDataModel wayPointsForRouteId:routeId] forRoute:route];
    }
    
    [self refreshAllStops];
}

- (void)aeDataModel:(AEDataModel *)aeDataModel didDeselectRoute:(NSNumber *)routeId {
    [self resetScreenName];
    
    Route *route = [aeDataModel routeForId:routeId];
    
    [self refreshVehicles:@[] forRoute:route];
    [self removeWaypointsForRoute:route];
    
    [self refreshAllStops];
}

- (void)resetMapRect:(BOOL)animated {
    
    if (AEDataModel.shared.selectedRoutes.count == 0 || self.mapView.overlays.count == 0) {
        [self zoomToLocation:CLLocationCoordinate2DMake(UCI_LATITUDE, UCI_LONGITUDE) animated:animated userLoc:false];
        return;
    }
    
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
    
    [self.mapView setVisibleMapRect:routeRect animated:animated];
    [self.locationButton setImage:self.locationButtonLocationImage forState:UIControlStateNormal];
    self.showingLocationImage = true;
}

- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshStops:(NSArray<Stop *> *)stops forRoute:(Route *)route {
    if ([aeDataModel.selectedRoutes containsObject:route.id] == false) {
        return;
    }
    
    [self refreshAllStops];
}

- (void)refreshAllStops {
    
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[AEStopAnnotation class]]) {
            AEStopAnnotation *stopAnnotation = annotation;
            [self.mapView removeAnnotation:stopAnnotation];
        }
    }
    [self.stopAnnotationForStopId removeAllObjects];
    
    for (NSNumber *routeId in AEDataModel.shared.selectedRoutes) {
        Route *route = [AEDataModel.shared routeForId:routeId];
        
        for (NSNumber *stopId in [AEDataModel.shared stopsForRouteId:route.id]) {
            if (self.stopAnnotationForStopId[stopId] == nil) {
                Stop *stop = [AEDataModel.shared stopForStopId:stopId];
                AEStopAnnotation *stopAnnotation = [[AEStopAnnotation alloc] initWithStop:stop];
                [self.mapView addAnnotation:stopAnnotation];
                self.stopAnnotationForStopId[stopId] = stopAnnotation;
                [stopAnnotation.routes addObject:route];
            } else {
                AEStopAnnotation *stopAnnotation = self.stopAnnotationForStopId[stopId];
                [stopAnnotation.routes addObject:route];
            }
        }
    }
}

- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshWaypoints:(RouteWaypoints *)waypoints forRoute:(Route *)route {
    if (waypoints == nil) {
        return;
    }
    if ([aeDataModel.selectedRoutes containsObject:route.id] == false) {
        return;
    }
    
    [self addWaypoints:waypoints forRoute:route];
}

- (void)addWaypoints:(RouteWaypoints *)waypoints forRoute:(Route *)route {

    // Convert to thing for mapkit
    MKMapPoint *routeMapPointsCArray = malloc(sizeof(MKMapPoint) * waypoints.points.count);
    // Make C Array
    [waypoints.points enumerateObjectsUsingBlock:^(NSValue *value, NSUInteger idx, BOOL *stop) {
        MKMapPoint point;
        [value getValue:&point];
        routeMapPointsCArray[idx] = point;
    }];
    
    MKPolyline *polyline = [MKPolyline polylineWithPoints:routeMapPointsCArray count:waypoints.points.count];
    [polyline setTitle:[route.id stringValue]];
    
    for (id<MKOverlay> overlay in self.mapView.overlays) {
        if ([overlay isKindOfClass:[MKPolyline class]]) {
            MKPolyline *oldPolyline = (MKPolyline *)overlay;
            if ([oldPolyline.title isEqualToString:[route.id stringValue]]) {
                [self.mapView removeOverlay:oldPolyline];
            }
        }
    }
    
    [self.mapView addOverlay:polyline];
    
    [self resetMapRect:false];
}

- (void)removeWaypointsForRoute:(Route *)route {
    for (id<MKOverlay> overlay in self.mapView.overlays) {
        if ([overlay isKindOfClass:[MKPolyline class]]) {
            MKPolyline *polyline = overlay;
            if ([polyline.title isEqualToString:[route.id stringValue]]) {
                [self.mapView removeOverlay:overlay];
            }
        }
    }
    
    [self resetMapRect:false];
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

- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshVehicles:(NSArray<Vehicle *> *)vehicleList forRoute:(Route *)route {
    if ([aeDataModel.selectedRoutes containsObject:route.id] == false) {
        return;
    }
        
    [self refreshVehicles:vehicleList forRoute:route];
    
}

- (void)refreshVehicles:(NSArray<Vehicle*> *)vehicleList forRoute:(Route *)route {
    // Make sure there's a route dict in there for the vehicle
    if (self.vehicleForRouteAndVehicleId[route.id] == nil) {
        self.vehicleForRouteAndVehicleId[route.id] = [NSMutableDictionary dictionary];
    }
    
    NSMutableSet *visited = [NSMutableSet setWithCapacity:vehicleList.count];
    for (Vehicle *vehicle in vehicleList) {
        [visited addObject:vehicle.id];
        
        AEVehicleAnnotation *vehicleAnnotation = self.vehicleForRouteAndVehicleId[route.id][vehicle.id];
        if (vehicleAnnotation != nil) {
            // Update
            vehicleAnnotation.vehicle = vehicle;
            
            AEVehicleAnnotationView *vehicleAnnotationView = (AEVehicleAnnotationView *)[self.mapView viewForAnnotation:vehicleAnnotation];
            vehicleAnnotationView.tintColor = [ColorConverter colorWithHexString:route.color];
            [vehicleAnnotationView setVehicleImage:vehicleAnnotation.vehiclePicture];
        } else {
            // Make new one
            AEVehicleAnnotation *vehicleAnnotation = [[AEVehicleAnnotation alloc] initWithVehicle:vehicle route:route];
            [self.mapView addAnnotation:vehicleAnnotation];
            self.vehicleForRouteAndVehicleId[route.id][vehicle.id] = vehicleAnnotation;
        }
    }
    
    NSMutableSet *toRemove = [NSMutableSet setWithArray:[self.vehicleForRouteAndVehicleId[route.id] allKeys]];
    [toRemove minusSet:visited];
    for (NSNumber *vehicleId in toRemove) {
        AEVehicleAnnotation *vehicleAnnotation = self.vehicleForRouteAndVehicleId[route.id][vehicleId];
        [self.mapView removeAnnotation:vehicleAnnotation];
        [self.vehicleForRouteAndVehicleId[route.id] removeObjectForKey:vehicleId];
    }

}

#pragma mark - MapKit methods

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    // Called for the route polylines

    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *polyline = (MKPolyline *)overlay;
        NSNumber *routeId = [NSNumber numberWithInteger:polyline.title.integerValue];
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
        Route *route = [AEDataModel.shared routeForId:routeId];
        
        renderer.strokeColor = [ColorConverter colorWithHexString:route.color];
        if (AEDataModel.shared.selectedRoutes.count > 1) {
            // If it's the second or third or so on line being added, do half alpha as a way
            // to better differentiate overlapping lines. This is how the website currently
            // does it, from what I saw.
            renderer.strokeColor = [renderer.strokeColor colorWithAlphaComponent:0.75];
        }
        renderer.lineWidth = 4.0;
        
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
        // Construct colors array from the selected lines, to be passed to the view
        NSMutableArray *colors = [NSMutableArray array];
        for (Route *route in stopAnnotation.routes) {
            [colors addObject:[ColorConverter colorWithHexString:route.color]];
        }

        
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
        
        vehicleAnnotationView.tintColor = [ColorConverter colorWithHexString:vehicleAnnotation.route.color];
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
    self.userLocation = userLocation;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (fabs(mapView.region.center.latitude - mapView.userLocation.coordinate.latitude) > 0.00001 &&
        fabs(mapView.region.center.longitude - mapView.userLocation.coordinate.longitude) > 0.00001) {
        [self.locationButton setImage:self.locationButtonLocationImage forState:UIControlStateNormal];
        self.showingLocationImage = true;
    }
}

- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshArrivals:(NSDictionary<NSNumber *,NSArray<Arrival *> *> *)arrivalsDict forStop:(Stop *)stop {
    
    if (self.selectedStopAnnotationView == nil) {
        NSLog(@"Got arrivals but we didn't tap anything!");
        return;
    }
    
    AEStopAnnotation *stopAnnotation = self.selectedStopAnnotationView.annotation;
    
    if (!NSClassFromString(@"UIStackView") || ![self.selectedStopAnnotationView respondsToSelector:@selector(detailCalloutAccessoryView)]) {
        // Set subtitle. We're not iOS9 with stack views and detail views
        stopAnnotation.subtitle = [stopAnnotation makeSubtitleForArrivalDict:arrivalsDict];
    
    } else if (arrivalsDict == nil) {
        stopAnnotation.subtitle = @"Error";
    } else {
        // We're good to go with the detail view
        
        __block UIStackView *stackView = [[UIStackView alloc] init];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionEqualSpacing;
        stackView.alignment = UIStackViewAlignmentLeading;
        stackView.spacing = 4;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [arrivalsDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *routeId, NSArray<Arrival*> *arrivalsList, BOOL *stop) {
            if ([AEDataModel.shared.selectedRoutes containsObject:routeId]) {
                Route *route = [AEDataModel.shared routeForId:routeId];
                
                NSArray *elements = [[NSBundle mainBundle] loadNibNamed:@"ArrivalPredictionView" owner:self options:nil];
                ArrivalPredictionView *arrivalsView = [elements firstObject];

                arrivalsView.textLabel.text = [stopAnnotation formattedSubtitleForArrivalList:arrivalsList abbreviation:route.shortName];
                arrivalsView.colorView.backgroundColor = [ColorConverter colorWithHexString:route.color];
                arrivalsView.tag = routeId.integerValue;
                
                UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(calloutAnnotationViewWasTapped:)];
                tapRecognizer.numberOfTouchesRequired = 1;
                tapRecognizer.numberOfTapsRequired = 1;
                [arrivalsView addGestureRecognizer:tapRecognizer];
                
                
                [stackView addArrangedSubview:arrivalsView];
            }
            
        }];
        
        
        self.selectedStopAnnotationView.detailCalloutAccessoryView = stackView;
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view isMemberOfClass:[AEStopAnnotationView class]]) {

        AEStopAnnotation *stopAnnotaton = (AEStopAnnotation *)view.annotation;
        self.selectedStopAnnotationView = view;
        stopAnnotaton.subtitle = @"Loading Arrivals...";
        [AEDataModel.shared refreshArrivalsForStop:stopAnnotaton.stop];
        
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(nonnull MKAnnotationView *)view {
    if ([view respondsToSelector:@selector(detailCalloutAccessoryView)]) {
        view.detailCalloutAccessoryView = nil;
    }
}

- (void)calloutAnnotationViewWasTapped:(UITapGestureRecognizer *)sender {
    UINavigationController *frontNavController = (UINavigationController *)self.navigationController;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    RouteDetailViewController *destVC = (RouteDetailViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RouteDetailView"];
    NSNumber *routeId = [NSNumber numberWithInteger:sender.view.tag];
    [destVC setRoute:[AEDataModel.shared routeForId:routeId]];
    
    [frontNavController pushViewController:destVC animated:YES];
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

- (void)zoomToLocation:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated userLoc:(BOOL)userLoc {
    
    MKCoordinateRegion mapRegion;
    mapRegion.center = coordinate;
    if (userLoc) {
        mapRegion.span.latitudeDelta = 0.01;
        mapRegion.span.longitudeDelta = 0.01;
    } else {
        mapRegion.span.latitudeDelta = 0.025;
        mapRegion.span.longitudeDelta = 0.025;
    }

    [self.mapView setRegion:mapRegion animated:animated];
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
