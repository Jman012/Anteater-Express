//
//  AEGetRouteDefinition.m
//  Anteater Express
//
//  Created by James Linnell on 12/1/15.
//
//

#import "AEGetRouteDefinition.h"

@interface AEGetRouteDefinition ()

@property (nonatomic, assign) NSInteger stopSetId;

@end

@implementation AEGetRouteDefinition

- (instancetype)initWithStopSetId:(NSInteger)theStopSetId {
    if (self = [super init]) {
        self.stopSetId = theStopSetId;
    }
    return self;
}

- (void)main {
    
    // Instantiating this will perform the network request
    RouteDefinitionDAO *routeDefinition = [[RouteDefinitionDAO alloc] initWithStopID:(int)self.stopSetId];
    //    sleep(1);
    
    dispatch_sync(dispatch_get_main_queue(), ^() {
        self.returnBlock(routeDefinition);
    });
}

@end
