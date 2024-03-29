//
//  AEDataModel.h
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "Region.h"
#import "Route.h"
#import "RouteWaypoints.h"
#import "Stop.h"
#import "Vehicle.h"
#import "Arrival.h"

@class AEDataModel;

@protocol AEDataModelDelegate <NSObject>
@optional
- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshRouteList:(NSArray<Route*> *)routeList;
- (void)aeDataModel:(AEDataModel *)aeDataModel didAddRoute:(Route *)route;
- (void)aeDataModel:(AEDataModel *)aeDataModel didRemoveRoute:(Route *)route;

- (void)aeDataModel:(AEDataModel *)aeDataModel didSelectRoute:(NSNumber *)routeId;
- (void)aeDataModel:(AEDataModel *)aeDataModel didDeselectRoute:(NSNumber *)routeId;

- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshVehicles:(NSArray<Vehicle*> *)vehicleList forRoute:(Route *)route;
- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshWaypoints:(RouteWaypoints *)waypoints forRoute:(Route *)route;
- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshStops:(NSArray<Stop*> *)stops forRoute:(Route *)route;
- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshArrivals:(NSDictionary<NSNumber*,NSArray<Arrival*>*> *)arrivalsDict forStop:(Stop *)stop;

- (void)aeDataModelDidGetErrorRefreshingRoutes:(AEDataModel *)aeDataModel;
- (void)aeDataModel:(AEDataModel *)aeDataModel didSetMapType:(MKMapType)mapType;


@end

@interface AEDataModel : NSObject

@property (nonatomic, strong) NSMutableArray<Route*> *routeList;
@property (nonatomic, strong) NSMutableArray<Stop*> *stopList;

+ (instancetype)shared;

- (void)addDelegate:(id<AEDataModelDelegate>)newDelegate;
- (void)removeDelegate:(id<AEDataModelDelegate>)oldDelegate;

- (void)selectRoute:(Route *)route;
- (void)deselectRoute:(Route *)route;
- (NSSet<NSNumber*> *)selectedRoutes;

- (void)refreshRoutes;
- (void)refreshVehiclesForRoute:(Route *)route;
- (void)refreshArrivalsForStop:(Stop *)stop;

- (Route *)routeForId:(NSNumber *)routeId;
- (NSArray<Vehicle*> *)vehiclesForRouteId:(NSNumber *)routeId;
- (RouteWaypoints *)wayPointsForRouteId:(NSNumber *)routeId;
- (NSArray<NSNumber*> *)stopsForRouteId:(NSNumber *)routeId;
- (Stop *)stopForStopId:(NSNumber *)stopId;

- (void)setMapType:(MKMapType)type;

/* Hard coded values for the transition from Tomcat server to UCIShuttles.com */
@property(nonatomic, strong) NSDictionary *routeDescriptions;
@property(nonatomic, strong) NSSet *routeFares;

@end
