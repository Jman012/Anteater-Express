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

@end

@implementation AEDataModel

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        self.delegates = [NSHashTable weakObjectsHashTable];
        self.selectedRouteIDsSet = [NSMutableSet set];
        
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
    NSError *e = nil;
    
    // Region
    [UCIShuttlesRequest requestRegions:^(NSArray<Region*> *regions, NSError *error) {
        NSLog(@"Regions: %@", regions);
        if (error != nil) {
            NSLog(@"Got error while getting regions: %@", e);
            return;
        }
        if (regions.count > 0) {
            self.region = regions.firstObject;
        } else {
            self.region = [[Region alloc] init];
            self.region.id = 0;
        }
        
        [self refreshRoutes];
    }];
    
}

- (void)refreshRoutes {
    if (self.region == nil) {
        [self refreshRegions];
        return;
    }
    
    NSError *e = nil;
    
    // Routes
    [UCIShuttlesRequest requestRoutesForRegion:self.region.id completion:^(NSArray<Region*> *routes, NSError *error) {
        NSLog(@"Routes: %@", routes);
        if (e != nil) {
            NSLog(@"Got error while getting routes for region %@: %@", self.region.id, e);
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
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didRefreshRouteList:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didRefreshRouteList:self.routeList];
                });
            }
        }
    }];
    
}

- (void)refreshVehiclesForRoute:(Route *)route {
    NSError *e = nil;
    
    // Routes
    [UCIShuttlesRequest requestVehiclesForRouteId:route.id completion:^(NSArray<Vehicle*> *vehicles, NSError *error) {
        NSLog(@"Routes: %@", vehicles);
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
