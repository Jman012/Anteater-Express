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
+ (void)requestWaypointsForRouteId:(NSNumber *)routeId completion:(void (^)(RouteWaypoints *waypoints, NSError *error))completionHandler;
+ (void)requestVehiclesForRouteId:(NSNumber *)routeId completion:(void (^)(NSArray<Vehicle*> *vehicles, NSError *error))completionHandler;
+ (void)requestStopsForRouteId:(NSNumber *)routeId directionId:(NSNumber *)directionId completion:(void (^)(NSArray<Stop*> *stops, NSError *error))completionHandler;
+ (void)requestArrivalsForStopId:(NSNumber *)stopId completion:(void (^)(NSDictionary<NSNumber*,NSArray<Arrival*>*> *arrivalsDict, NSError *error))completionHandler;
@end
