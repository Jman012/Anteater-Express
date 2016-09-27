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
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, Route*> *routeForRouteId;

@property (nonatomic, assign) BOOL gettingRegion;
@property (nonatomic, assign) BOOL gettingRoutes;
@property (nonatomic, strong) NSMutableSet *gettingRouteById;
@property (nonatomic, strong) NSMutableSet *gettingWaypointsById;
@property (nonatomic, strong) NSMutableSet *gettingVehiclesById;
@property (nonatomic, strong) NSMutableSet *gettingDirectionsById;
@property (nonatomic, strong) NSMutableSet *gettingStopsById;
@property (nonatomic, strong) NSMutableSet *gettingArrivalsById;

@property (nonatomic, strong) NSTimer *vehicleTimer;

@end

@implementation AEDataModel

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        self.delegates = [NSHashTable weakObjectsHashTable];
        self.selectedRouteIDsSet = [NSMutableSet set];
        self.routeForRouteId = [NSMutableDictionary dictionary];
        
        self.gettingRegion = false;
        self.gettingRoutes = false;
        self.gettingRouteById = [NSMutableSet set];
        self.gettingWaypointsById = [NSMutableSet set];
        self.gettingVehiclesById = [NSMutableSet set];
        self.gettingDirectionsById = [NSMutableSet set];
        self.gettingStopsById = [NSMutableSet set];
        self.gettingArrivalsById = [NSMutableSet set];
        
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
    [self refreshRoutes];
    
    [self loadSelectedRoutes];
    
    self.vehicleTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(refreshVehiclesForSelectedRoutes) userInfo:nil repeats:true];
}

- (void)loadSelectedRoutes {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *ids = [userDefaults objectForKey:@"SelectedRouteIds"];
    self.selectedRouteIDsSet = [NSMutableSet setWithArray:ids];
    [self refreshRoutes];
}

- (void)saveSelectedRoutes {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *selectedRouteIdsArray = [NSArray arrayWithArray:self.selectedRouteIDsSet.allObjects];
    [userDefaults setObject:selectedRouteIdsArray forKey:@"SelectedRouteIds"];
    [userDefaults synchronize];
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

#pragma mark - Routes

- (void)refreshRegions {
    if (self.gettingRegion) {
        return;
    }
    self.gettingRegion = true;
    
    NSError *e = nil;
    [UCIShuttlesRequest requestRegions:^(NSArray<Region*> *regions, NSError *error) {
        NSLog(@"Regions: %@", regions);
        if (error != nil) {
            NSLog(@"Got error while getting regions: %@", e);
            self.gettingRegion = false;
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
    
    NSError *e = nil;
    
    // Routes
    [UCIShuttlesRequest requestRoutesForRegion:self.region.id completion:^(NSArray<Region*> *routes, NSError *error) {
        NSLog(@"Routes: %@", routes);
        if (e != nil) {
            NSLog(@"Got error while getting routes for region %@: %@", self.region.id, e);
            self.gettingRoutes = false;
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
        self.routeList = [NSMutableArray arrayWithArray:routes];
        self.routeForRouteId = [NSMutableDictionary dictionaryWithCapacity:self.routeList.count];
        for (Route *route in self.routeList) {
            self.routeForRouteId[route.id] = route;
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

- (void)refreshVehiclesForRoute:(Route *)route {
    if ([self.gettingVehiclesById containsObject:route.id]) {
        return;
    }
    [self.gettingVehiclesById addObject:route.id];
    
    NSError *e = nil;
    [UCIShuttlesRequest requestVehiclesForRouteId:route.id completion:^(NSArray<Vehicle*> *vehicles, NSError *error) {
        NSLog(@"Vehicles: %@", vehicles);
        if (e != nil) {
            NSLog(@"Got error while getting routes for region %@: %@", self.region.id, e);
            return;
        }
        route.vehicles = [NSMutableArray arrayWithArray:vehicles];
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

#pragma mark - Delegation Methods

- (void)addDelegate:(id<AEDataModelDelegate>)newDelegate {
    [self.delegates addObject:newDelegate];
}

- (void)removeDelegate:(id<AEDataModelDelegate>)oldDelegate {
    [self.delegates removeObject:oldDelegate];
}



@end
