//
//  AEGetRouteDefinition.h
//  Anteater Express
//
//  Created by James Linnell on 12/1/15.
//
//

#import <Foundation/Foundation.h>

#import "RouteDefinitionDAO.h"

@interface AEGetRouteDefinition : NSOperation

@property (nonatomic, strong) void (^returnBlock)(RouteDefinitionDAO *routeDefinition);

- (instancetype)initWithStopSetId:(NSInteger)theStopSetId;

@end
