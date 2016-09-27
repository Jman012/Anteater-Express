//
//  UCIShuttlesRequest.h
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import <Foundation/Foundation.h>

#import "Region.h"
#import "Route.h"
#import "RouteWaypoints.h"
#import "Stop.h"
#import "Vehicle.h"
#import "Direction.h"
#import "Arrival.h"

@interface UCIShuttlesRequest : NSObject

+ (void)requestRegions:(void (^)(NSArray<Region*> *regions, NSError *error))completionHandler;
+ (void)requestRoutesForRegion:(NSNumber *)regionId completion:(void (^)(NSArray<Region*> *regions, NSError *error))completionHandler;
+ (Route *)requestRouteForId:(NSNumber *)routeId error:(NSError **)error;
+ (RouteWaypoints *)requestWaypointsForRouteId:(NSNumber *)routeId error:(NSError **)error;
+ (void)requestVehiclesForRouteId:(NSNumber *)routeId completion:(void (^)(NSArray<Vehicle*> *vehicles, NSError *error))completionHandler;
+ (NSArray<Direction*> *)requestDirectionsForRouteId:(NSNumber *)routeId error:(NSError **)error;
+ (NSArray<Stop*> *)requestStopsForRouteId:(NSNumber *)routeId directionId:(NSNumber *)directionId error:(NSError **)error;
+ (NSArray<Arrival*> *)requestArrivalsForStopId:(NSNumber *)stopId error:(NSError **)error;

@end
