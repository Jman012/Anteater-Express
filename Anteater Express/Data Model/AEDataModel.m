//
//  AEDataModel.m
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import "AEDataModel.h"

#import "UCIShuttlesRequest.h"

@interface AEDataModel ()

@property (nonatomic, strong) NSHashTable *delegates;

@property (nonatomic, strong) Region *region;
@property (nonatomic, strong) NSMutableSet<NSNumber*> *selectedRouteIDsSet;
// Route.id -> Route
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, Route*> *routeForRouteId;
// Route.id -> RouteWayPoints
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, RouteWaypoints*> *waypointsForRouteId;
// Route.id -> @[Vehicle]
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSArray<Vehicle*>*> *vehiclesForRouteId;
// Route.id -> @[Stop.id]
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSArray<NSNumber*>*> *stopsForRouteId;
// Stop.id -> Stop
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, Stop*> *stopForStopId;

@property (nonatomic, assign) BOOL gettingRegion;
@property (nonatomic, assign) BOOL gettingRoutes;
@property (nonatomic, strong) NSMutableSet *gettingRouteById;
@property (nonatomic, strong) NSMutableSet *gettingWaypointsById;
@property (nonatomic, strong) NSMutableSet *gettingVehiclesById;
@property (nonatomic, strong) NSMutableSet *gettingDirectionsById;
@property (nonatomic, strong) NSMutableSet *gettingStopsById;
@property (nonatomic, strong) NSMutableSet *gettingArrivalsById;

@property (nonatomic, strong) NSTimer *selectedVehiclesTimer;
@property (nonatomic, strong) NSTimer *allVehiclesTimer;
@property (nonatomic, strong) NSTimer *routesTimer;

@end

@implementation AEDataModel

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        self.delegates = [NSHashTable weakObjectsHashTable];
        self.selectedRouteIDsSet = [NSMutableSet set];
        self.routeForRouteId = [NSMutableDictionary dictionary];
        self.waypointsForRouteId = [NSMutableDictionary dictionary];
        self.vehiclesForRouteId = [NSMutableDictionary dictionary];
        self.stopsForRouteId = [NSMutableDictionary dictionary];
        self.stopForStopId = [NSMutableDictionary dictionary];
        
        self.gettingRegion = false;
        self.gettingRoutes = false;
        self.gettingRouteById = [NSMutableSet set];
        self.gettingWaypointsById = [NSMutableSet set];
        self.gettingVehiclesById = [NSMutableSet set];
        self.gettingDirectionsById = [NSMutableSet set];
        self.gettingStopsById = [NSMutableSet set];
        self.gettingArrivalsById = [NSMutableSet set];
        
        self.routeDescriptions =
        @{
          @317:@"ACC Housing services Camino del Sol/Vista del Campo/Vista del Campo Norte",
          @932:@"ACC Summer Combined Service for Camino del Sol/Vista del Campo/Vista del Campo Norte",
          @308:@"Arroyo Vista Housing, UCI Admin, ARC",
          @527:@"Camino del Sol Housing, UCI Admin",
          @941:@"District, Diamond Jamboree, UCI Admin, East Campus Housing",
          @762:@"Irvine Spectrum, UCI Admin, East Campus Housing",
          @176:@"Circle Around UCI Campus Core",
          @3161:@"Circle Around UCI Campus Core",
          @530:@"Vista del Campo Housing - UCI Admin",
          @528:@"Vista del Campo Norte Housing - UCI Admin",
          @305:@"Parkwest Apartments - Carlson Ave - UCI Claire Trevor School of the Arts",
          @2830:@"Park West Summer Route"
          };
        self.routeFares = [NSSet setWithArray:@[@932, @941, @762, @305, @2830]];
        
        [self initialize];
    }
    return self;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static AEDataModel *instance;
    dispatch_once(&onceToken, ^{
        instance = [[AEDataModel alloc] init];
    });
    return instance;
}

- (void)initialize {
    
    
    [self loadSelectedRoutes];
    [self refreshRoutes];
    
    // Refresh the selected routes' vehicles every 5 seconds, refresh all routes every 10 minutes.
    self.selectedVehiclesTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(refreshVehiclesForSelectedRoutes) userInfo:nil repeats:true];
    // All vehicles (for the side menu) every 3 minutes
    self.selectedVehiclesTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 * 60.0 target:self selector:@selector(refreshVehiclesForAllRoutes) userInfo:nil repeats:true];
    // Route list every 10 minutes.
    self.routesTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 * 60.0 target:self selector:@selector(refreshRoutes) userInfo:nil repeats:true];
}

- (void)loadSelectedRoutes {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *ids = [userDefaults objectForKey:@"SelectedRouteIds"];
    self.selectedRouteIDsSet = [NSMutableSet setWithArray:ids];
}

- (void)saveSelectedRoutes {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *selectedRouteIdsArray = [NSArray arrayWithArray:self.selectedRouteIDsSet.allObjects];
    [userDefaults setObject:selectedRouteIdsArray forKey:@"SelectedRouteIds"];
    [userDefaults synchronize];
}

#pragma mark - Getters

- (Route *)routeForId:(NSNumber *)routeId {
    return self.routeForRouteId[routeId];
}

- (NSArray<Vehicle*> *)vehiclesForRouteId:(NSNumber *)routeId {
    return self.vehiclesForRouteId[routeId];
}

- (RouteWaypoints *)wayPointsForRouteId:(NSNumber *)routeId {
    return self.waypointsForRouteId[routeId];
}

- (NSArray<NSNumber*> *)stopsForRouteId:(NSNumber *)routeId {
    return self.stopsForRouteId[routeId];
}

- (Stop *)stopForStopId:(NSNumber *)stopId {
    return self.stopForStopId[stopId];
}

#pragma mark - Selected Routes

- (void)selectRoute:(Route *)route {
    if ([self.selectedRouteIDsSet containsObject:route.id] == false) {
        [self.selectedRouteIDsSet addObject:route.id];
        
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didSelectRoute:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didSelectRoute:route.id];
                });
            }
        }
        
        [self refreshVehiclesForRoute:route];
        
        [self saveSelectedRoutes];
    }
}

- (void)deselectRoute:(Route *)route {
    if ([self.selectedRouteIDsSet containsObject:route.id] == true) {
        [self.selectedRouteIDsSet removeObject:route.id];
        
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didDeselectRoute:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didDeselectRoute:route.id];
                });
            }
        }
        
        [self saveSelectedRoutes];
    }
}

- (NSSet<NSNumber*> *)selectedRoutes {
    return [NSSet setWithSet:self.selectedRouteIDsSet];
}

#pragma mark - Refresh information

- (void)refreshRegions {
    if (self.gettingRegion) {
        return;
    }
    self.gettingRegion = true;
    
    [UCIShuttlesRequest requestRegions:^(NSArray<Region*> *regions, NSError *error) {
        
        if (error != nil) {
            NSLog(@"Got error while getting regions: %@", error);
            self.gettingRegion = false;
            
            for (id<AEDataModelDelegate> del in self.delegates) {
                if ([del respondsToSelector:@selector(aeDataModelDidGetErrorRefreshingRoutes:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [del aeDataModelDidGetErrorRefreshingRoutes:self];
                    });
                }
            }
            return;
        }
        if (regions.count > 0) {
            self.region = regions.firstObject;
        } else {
            self.region = [[Region alloc] init];
            self.region.id = 0;
        }
        
        self.gettingRegion = false;
        [self refreshRoutes];
    }];
    
}

- (void)refreshRoutes {
    if (self.gettingRoutes) {
        return;
    }
    self.gettingRoutes = true;
    
    if (self.region == nil) {
        self.gettingRoutes = false;
        [self refreshRegions];
        return;
    }
    
    // Routes
    [UCIShuttlesRequest requestRoutesForRegion:self.region.id completion:^(NSArray<Route*> *routes, NSError *error) {
        NSLog(@"Got routes (%lu)", (long)routes.count);
        if (error != nil) {
            NSLog(@"Got error while getting routes for region %@: %@", self.region.id, error);
            self.gettingRoutes = false;
            
            for (id<AEDataModelDelegate> del in self.delegates) {
                if ([del respondsToSelector:@selector(aeDataModelDidGetErrorRefreshingRoutes:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [del aeDataModelDidGetErrorRefreshingRoutes:self];
                    });
                }
            }
            return;
        }
        
        if (self.routeList == nil) {
            // First time loading the route list, so lets notify delegate of selected routes
            NSMutableSet *foundIds = [NSMutableSet set];
            for (NSNumber* routeId in self.selectedRouteIDsSet) {
                [foundIds addObject:routeId];
                
                for (id<AEDataModelDelegate> del in self.delegates) {
                    if ([del respondsToSelector:@selector(aeDataModel:didSelectRoute:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^() {
                            [del aeDataModel:self didSelectRoute:routeId];
                        });
                    }
                }
            }
            
            [self.selectedRouteIDsSet unionSet:foundIds];
        }
        
        // Before setting new routes, need to see if there's any we need to delete
        NSMutableSet *idsToRemove = [NSMutableSet set];
        for (NSNumber *routeId in self.selectedRouteIDsSet) {
            BOOL remove = true;
            for (Route *newRoute in routes) {
                if ([routeId isEqualToNumber:newRoute.id]) {
                    remove = false;
                }
            }
            if (remove) {
                [idsToRemove addObject:routeId];
            }
        }
        for (NSNumber *routeId in idsToRemove) {
            [self deselectRoute:self.routeForRouteId[routeId]];
        }
        
        // Then set the new route list and do other stuff.
        self.routeList = [NSMutableArray arrayWithArray:routes];
        self.routeForRouteId = [NSMutableDictionary dictionaryWithCapacity:self.routeList.count];
        for (Route *route in self.routeList) {
            self.routeForRouteId[route.id] = route;
            
            if ([self wayPointsForRouteId:route.id] == nil) {
                [self refreshWaypointsForRoute:route];
            }
            if ([self stopsForRouteId:route.id] == nil) {
                [self refreshStopsForRoute:route];
            }
        }
        
        
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didRefreshRouteList:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didRefreshRouteList:self.routeList];
                });
            }
        }
        
        self.gettingRoutes = false;
    }];
    
}

- (void)refreshVehiclesForSelectedRoutes {
    for (NSNumber *routeId in self.selectedRouteIDsSet) {
        Route *route = self.routeForRouteId[routeId];
        [self refreshVehiclesForRoute:route];
    }
}

- (void)refreshVehiclesForAllRoutes {
    for (Route *route in self.routeList) {
        [self refreshVehiclesForRoute:route];
    }
}

- (void)refreshVehiclesForRoute:(Route *)route {
    if (route == nil) {
        return;
    }
    if ([self.gettingVehiclesById containsObject:route.id]) {
        return;
    }
    [self.gettingVehiclesById addObject:route.id];
    
    [UCIShuttlesRequest requestVehiclesForRouteId:route.id completion:^(NSArray<Vehicle*> *vehicles, NSError *error) {

        if (error != nil) {
            NSLog(@"Got error while getting vehicles for route %@: %@", route.id, error);
            [self.gettingVehiclesById removeObject:route.id];
            for (id<AEDataModelDelegate> del in self.delegates) {
                if ([del respondsToSelector:@selector(aeDataModel:didRefreshVehicles:forRoute:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [del aeDataModel:self didRefreshVehicles:@[] forRoute:route];
                    });
                }
            }

            return;
        }

        self.vehiclesForRouteId[route.id] = [NSMutableArray arrayWithArray:vehicles];
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didRefreshVehicles:forRoute:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didRefreshVehicles:vehicles forRoute:route];
                });
            }
        }
        
        [self.gettingVehiclesById removeObject:route.id];
    }];
}

- (void)refreshWaypointsForRoute:(Route *)route {
    if (route == nil) {
        return;
    }
    if ([self.gettingWaypointsById containsObject:route.id]) {
        return;
    }
    [self.gettingWaypointsById addObject:route.id];
    
    [UCIShuttlesRequest requestWaypointsForRouteId:route.id completion:^(RouteWaypoints *waypoints, NSError *error) {
        if (error != nil) {
            NSLog(@"Got error while getting waypoints for route %@: %@", route.id, error);
            [self.gettingWaypointsById removeObject:route.id];
            for (id<AEDataModelDelegate> del in self.delegates) {
                if ([del respondsToSelector:@selector(aeDataModel:didRefreshWaypoints:forRoute:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [del aeDataModel:self didRefreshWaypoints:nil forRoute:route];
                    });
                }
            }
            return;
        }
        
        self.waypointsForRouteId[route.id] = waypoints;
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didRefreshWaypoints:forRoute:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didRefreshWaypoints:waypoints forRoute:route];
                });
            }
        }
        
        [self.gettingWaypointsById removeObject:route.id];
    }];
}

- (void)refreshStopsForRoute:(Route *)route {
    if (route == nil) {
        return;
    }
    if ([self.gettingStopsById containsObject:route.id]) {
        return;
    }
    [self.gettingStopsById addObject:route.id];
    
    [UCIShuttlesRequest requestStopsForRouteId:route.id directionId:@0 completion:^(NSArray<Stop*> *stops, NSError *error) {

        if (error != nil) {
            NSLog(@"Got error while getting stops for route %@: %@", route.id, error);
            [self.gettingStopsById removeObject:route.id];
            for (id<AEDataModelDelegate> del in self.delegates) {
                if ([del respondsToSelector:@selector(aeDataModel:didRefreshStops:forRoute:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [del aeDataModel:self didRefreshStops:@[] forRoute:route];
                    });
                }
            }
            return;
        }

        NSMutableArray *stopIds = [NSMutableArray arrayWithCapacity:stops.count];
        for (Stop *stop in stops) {
            self.stopForStopId[stop.id] = stop;
            [stopIds addObject:stop.id];
        }
        self.stopsForRouteId[route.id] = stopIds;

        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didRefreshStops:forRoute:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didRefreshStops:stops forRoute:route];
                });
            }
        }
        
        [self.gettingStopsById removeObject:route.id];
    }];
}

- (void)refreshArrivalsForStop:(Stop *)stop {
    if (stop == nil) {
        return;
    }
    if ([self.gettingArrivalsById containsObject:stop.id]) {
        return;
    }
    [self.gettingArrivalsById addObject:stop.id];
    
    [UCIShuttlesRequest requestArrivalsForStopId:stop.id completion:^(NSDictionary<NSNumber*,NSArray<Arrival*>*> *arrivalsDict, NSError *error) {

        if (error != nil) {
            NSLog(@"Got error while getting arrivals for stop %@: %@", stop.id, error);
            [self.gettingArrivalsById removeObject:stop.id];
            for (id<AEDataModelDelegate> del in self.delegates) {
                if ([del respondsToSelector:@selector(aeDataModel:didRefreshArrivals:forStop:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [del aeDataModel:self didRefreshArrivals:nil forStop:stop];
                    });
                }
            }
            return;
        }
        
        // Don't need to save this anywhere honestly
        
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didRefreshArrivals:forStop:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didRefreshArrivals:arrivalsDict forStop:stop];
                });
            }
        }
        
        [self.gettingArrivalsById removeObject:stop.id];
    }];
}

#pragma mark - Delegation Methods

- (void)addDelegate:(id<AEDataModelDelegate>)newDelegate {
    [self.delegates addObject:newDelegate];
}

- (void)removeDelegate:(id<AEDataModelDelegate>)oldDelegate {
    [self.delegates removeObject:oldDelegate];
}



@end
