//
//  AEGetVehiclesOp.h
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import <Foundation/Foundation.h>

#import "RouteVehiclesDAO.h"

@interface AEGetVehiclesOp : NSOperation

@property (nonatomic, strong) void (^returnBlock)(RouteVehiclesDAO *routeDefinition);

- (instancetype)initWithStopSetId:(NSInteger)theStopSetId;

@end
