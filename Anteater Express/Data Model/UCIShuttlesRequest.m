//
//  UCIShuttlesRequest.m
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import "UCIShuttlesRequest.h"
#import <MapKit/MapKit.h>

#import "AEDataModel.h"

@implementation UCIShuttlesRequest

#pragma mark - Main requests

+ (void)requestRegions:(void (^)(NSArray<Region*> *regions, NSError *error))completionHandler {
    [UCIShuttlesRequest sendRequest:@"/Regions" completion:^(NSArray *regionJson, NSError *error) {
        if (error != nil) {
            completionHandler(nil, error);
            return;
        }
        
        NSMutableArray<Region*> *regions = [NSMutableArray arrayWithCapacity:regionJson.count];
        @try {
            for (NSDictionary *regionDict in regionJson) {
                NSNumber *theId = regionDict[@"ID"];
                
                Region *newRegion = [[Region alloc] init];
                newRegion.id = theId;
                [regions addObject:newRegion];
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading regions" code:1 userInfo:nil]);
        } @finally {
            completionHandler([NSArray arrayWithArray:regions], nil);
        }
    }];
}

+ (void)requestRoutesForRegion:(NSNumber *)regionId completion:(void (^)(NSArray<Route*> *regions, NSError *error))completionHandler {
    [UCIShuttlesRequest sendRequest:[NSString stringWithFormat:@"/Region/%@/Routes", regionId] completion:^(NSArray *routeJson, NSError *error) {
        
        if (error != nil) {
            completionHandler(nil, error);
            return;
        }
        
        NSMutableArray<Route*> *routes = [NSMutableArray arrayWithCapacity:routeJson.count];
        @try {
            for (NSDictionary *routeDict in routeJson) {
                NSNumber *theId = routeDict[@"ID"];
                NSString *color = routeDict[@"Color"];
                NSString *name = routeDict[@"Name"];
                name = [name componentsSeparatedByString:@" - "].lastObject;
                name = [name stringByReplacingOccurrencesOfString:@"-" withString:@" - "];
                NSString *scheduleName = [name stringByReplacingOccurrencesOfString:@" Weekday" withString:@""];
                scheduleName = [scheduleName stringByReplacingOccurrencesOfString:@" Weekend" withString:@""];
                NSString *shortName = routeDict[@"ShortName"];
                
                NSString *desc = AEDataModel.shared.routeDescriptions[theId];
                BOOL fare = [AEDataModel.shared.routeFares containsObject:theId];
                
                Route *newRoute = [[Route alloc] init];
                newRoute.id = theId;
                newRoute.color = color;
                newRoute.name = name;
                newRoute.shortName = shortName;
                newRoute.scheduleName = scheduleName;
                newRoute.desc = desc;
                newRoute.fare = fare;
                [routes addObject:newRoute];
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading routes" code:1 userInfo:nil]);
        } @finally {
            completionHandler([NSArray arrayWithArray:routes], nil);
        }

    }];
}

+ (Route *)requestRouteForId:(NSNumber *)routeId error:(NSError **)error {
    
}

+ (void)requestWaypointsForRouteId:(NSNumber *)routeId completion:(void (^)(RouteWaypoints *waypoints, NSError *error))completionHandler {
    [UCIShuttlesRequest sendRequest:[NSString stringWithFormat:@"/Route/%@/Waypoints", routeId] completion:^(NSArray *waypointsJson, NSError *error) {
        
        if (error != nil) {
            completionHandler(nil, error);
            return;
        }
        
        
        if (waypointsJson.count == 0) {
            completionHandler(nil, [NSError errorWithDomain:@"No waypoints found" code:1 userInfo:nil]);
            return;
        }
        NSArray *waypointsJsonArray = waypointsJson[0];
        
        RouteWaypoints *waypoints = [[RouteWaypoints alloc] init];
        NSMutableArray *points = [NSMutableArray arrayWithCapacity:waypointsJsonArray.count];
        @try {
            for (NSDictionary *waypointDict in waypointsJsonArray) {
                NSNumber *lat = waypointDict[@"Latitude"];
                NSNumber *lon = waypointDict[@"Longitude"];
                
                CLLocationDegrees latitude  = lat.doubleValue;
                CLLocationDegrees longitude = lon.doubleValue;
                
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
                
                NSValue *value = [NSValue valueWithBytes:&mapPoint objCType:@encode(MKMapPoint)];
                [points addObject:value];
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading waypoints" code:1 userInfo:nil]);
        } @finally {
            waypoints.points = points;
            completionHandler(waypoints, nil);
        }
        
    }];
}

+ (void)requestVehiclesForRouteId:(NSNumber *)routeId completion:(void (^)(NSArray<Vehicle*> *vehicles, NSError *error))completionHandler {
    [UCIShuttlesRequest sendRequest:[NSString stringWithFormat:@"/Route/%@/Vehicles", routeId] completion:^(NSArray *vehiclesJson, NSError *error) {
        
        if (error != nil) {
            completionHandler(nil, error);
            return;
        }
        
        NSMutableArray<Vehicle*> *vehicles = [NSMutableArray arrayWithCapacity:vehiclesJson.count];
        @try {
            for (NSDictionary *vehicleDict in vehiclesJson) {
                Vehicle *newVehicle = [[Vehicle alloc] init];
                newVehicle.id = vehicleDict[@"ID"];
                newVehicle.name = vehicleDict[@"Name"];
                newVehicle.updated = vehicleDict[@"Updated"];
                newVehicle.updatedAgo = vehicleDict[@"UpdatedAgo"];
                newVehicle.latitude = vehicleDict[@"Latitude"];
                newVehicle.longitude = vehicleDict[@"Longitude"];
                newVehicle.speed = vehicleDict[@"Speed"];
                newVehicle.heading = vehicleDict[@"Heading"];
                newVehicle.doorStatus = vehicleDict[@"DoorStatus"];
                
                [vehicles addObject:newVehicle];
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading vehicles" code:1 userInfo:nil]);
        } @finally {
            completionHandler([NSArray arrayWithArray:vehicles], nil);
        }
        
    }];
}

+ (NSArray<Direction*> *)requestDirectionsForRouteId:(NSNumber *)routeId error:(NSError **)error {

}

+ (void)requestStopsForRouteId:(NSNumber *)routeId directionId:(NSNumber *)directionId completion:(void (^)(NSArray<Stop*> *stops, NSError *error))completionHandler {
    
    [UCIShuttlesRequest sendRequest:[NSString stringWithFormat:@"/Route/%@/Direction/0/Stops", routeId] completion:^(NSArray *stopsJson, NSError *error) {
        
        if (error != nil) {
            completionHandler(nil, error);
            return;
        }
        
        NSMutableArray<Stop*> *stops = [NSMutableArray arrayWithCapacity:stopsJson.count];
        @try {
            for (NSDictionary *stopDict in stopsJson) {
                Stop *newStop = [[Stop alloc] init];
                newStop.id = stopDict[@"ID"];
                newStop.latitude = stopDict[@"Latitude"];
                newStop.longitude = stopDict[@"Longitude"];
                newStop.name = stopDict[@"Name"];
                
                
                [stops addObject:newStop];
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading stop" code:1 userInfo:nil]);
        } @finally {
            completionHandler([NSArray arrayWithArray:stops], nil);
        }
        
    }];
}

+ (void)requestArrivalsForStopId:(NSNumber *)stopId completion:(void (^)(NSDictionary<NSNumber*,NSArray<Arrival*>*> *arrivalsDict, NSError *error))completionHandler {
    [UCIShuttlesRequest sendRequest:[NSString stringWithFormat:@"/Stop/%@/Arrivals", stopId] completion:^(NSArray *arrivalsJson, NSError *error) {
        
        if (error != nil) {
            completionHandler(nil, error);
            return;
        }
        
        // Route.id -> @[Arrival]
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        @try {
            for (NSDictionary *routeDict in arrivalsJson) {
                NSNumber *routeId = routeDict[@"RouteID"];
                dict[routeId] = [NSMutableArray array];
                for (NSDictionary *arrivalDict in routeDict[@"Arrivals"]) {
                    Arrival *newArrival = [[Arrival alloc] init];
                    newArrival.vehicleID = arrivalDict[@"VehicleID"];
                    newArrival.vehicleName = arrivalDict[@"VehicleName"];
                    newArrival.secondsToArrival = arrivalDict[@"SecondsToArrival"];
                    
                    [dict[routeId] addObject:newArrival];
                }
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading stop" code:1 userInfo:nil]);
        } @finally {
            completionHandler(dict, nil);
        }
        
    }];
}

#pragma mark - General Request

+ (void)sendRequest:(NSString *)path completion:(void (^)(NSArray *jsonData, NSError *error))completion {
    NSString *fullPath = [NSString stringWithFormat:@"https://ucishuttles.com%@", path];

    NSURL *url = [NSURL URLWithString:fullPath];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod: @"GET"];
    [request setTimeoutInterval:30];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            completion(nil, error);
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode != 200) {
                completion(nil, [NSError errorWithDomain:@"Bad response" code:2 userInfo:nil]);
                return;
            }
        }
        
        if (data == nil) {
            completion(nil, [NSError errorWithDomain:@"No data" code:3 userInfo:nil]);
            return;
        }
        
        // Convert to JSON
        NSError *jsonError = nil;
        NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError != nil) {
            completion(nil, jsonError);
            return;
        }
        completion(jsonData, nil);
        
    }];
    [dataTask resume];

}

@end
