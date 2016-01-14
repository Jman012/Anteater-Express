//
//  AEGetVehiclesOp.m
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import "AEGetVehiclesOp.h"

@interface AEGetVehiclesOp ()

@property (nonatomic, assign) NSInteger stopSetId;

@end

@implementation AEGetVehiclesOp

- (instancetype)initWithStopSetId:(NSInteger)theStopSetId {
    if (self = [super init]) {
        self.stopSetId = theStopSetId;
    }
    return self;
}

- (void)main {
    
    // Instantiating this will perform the network request
    RouteVehiclesDAO *routeVehicles = [[RouteVehiclesDAO alloc] initWithStopID:(int)self.stopSetId];
    //    sleep(1);
    
    dispatch_sync(dispatch_get_main_queue(), ^() {
        self.returnBlock(routeVehicles);
    });
}

@end
