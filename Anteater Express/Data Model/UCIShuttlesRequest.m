//
//  UCIShuttlesRequest.m
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import "UCIShuttlesRequest.h"

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

+ (void)requestRoutesForRegion:(NSNumber *)regionId completion:(void (^)(NSArray<Region*> *regions, NSError *error))completionHandler {
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
                NSString *shortName = routeDict[@"ShortName"];
                // BOOL fare = regionDict[@""];
                // NSString *description = regionDict[@""];
                
                Route *newRoute = [[Route alloc] init];
                newRoute.id = theId;
                newRoute.color = color;
                newRoute.name = name;
                newRoute.shortName = shortName;
                [routes addObject:newRoute];
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading routes" code:1 userInfo:nil]);
        } @finally {
            completionHandler([NSArray arrayWithArray:routes], nil);
        }

    }];
}

+ (Route *)requestRouteForId:(NSInteger)routeId error:(NSError **)error {
    
}

+ (RouteWaypoints *)requestWaypointsForRouteId:(NSInteger)routeId error:(NSError **)error {
    
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
                newVehicle.name = vehicleDict[@"Updated"];
                newVehicle.name = vehicleDict[@"UpdatedAgo"];
                newVehicle.name = vehicleDict[@"Latitude"];
                newVehicle.name = vehicleDict[@"Longitude"];
                newVehicle.name = vehicleDict[@"Speed"];
                newVehicle.name = vehicleDict[@"Heading"];
                
                [vehicles addObject:newVehicle];
            }
        } @catch (NSException *exception) {
            completionHandler(nil, [NSError errorWithDomain:@"There was an error loading routes" code:1 userInfo:nil]);
        } @finally {
            completionHandler([NSArray arrayWithArray:vehicles], nil);
        }
        
    }];
}

+ (NSArray<Direction*> *)requestDirectionsForRouteId:(NSInteger)routeId error:(NSError **)error {
    
}

+ (NSArray<Stop*> *)requestStopsForRouteId:(NSInteger)routeId directionId:(NSInteger)directionId error:(NSError **)error {
    
}

+ (NSArray<Arrival*> *)requestArrivalsForStopId:(NSInteger)stopId error:(NSError **)error {
    
}

#pragma mark - General Request

+ (void)sendRequest:(NSString *)path completion:(void (^)(NSArray *jsonData, NSError *error))completion {
    NSString *fullPath = [NSString stringWithFormat:@"https://ucishuttles.com%@", path];
    NSLog(@"Requesting: %@", fullPath);
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
        
        NSLog(@"Response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
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
