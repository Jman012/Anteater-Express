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
@property (nonatomic, strong) NSMutableSet<Route*> *selectedRoutesSet;

@end

@implementation AEDataModel

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        self.delegates = [NSHashTable weakObjectsHashTable];
        self.selectedRoutesSet = [NSMutableSet set];
        
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
}

#pragma mark - Selected Routes

- (void)selectRoute:(Route *)route {
    if ([self.selectedRoutesSet containsObject:route] == false) {
        [self.selectedRoutesSet addObject:route];
        
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didSelectRoute:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didSelectRoute:route];
                });
            }
        }
    }
}

- (void)deselectRoute:(Route *)route {
    if ([self.selectedRoutesSet containsObject:route] == true) {
        [self.selectedRoutesSet removeObject:route];
        
        for (id<AEDataModelDelegate> del in self.delegates) {
            if ([del respondsToSelector:@selector(aeDataModel:didDeselectRoute:)]) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [del aeDataModel:self didDeselectRoute:route];
                });
            }
        }
    }
}

- (NSSet<Route*> *)selectedRoutes {
    return [NSSet setWithSet:self.selectedRoutesSet];
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
