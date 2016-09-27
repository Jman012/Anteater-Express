//
//  Route.h
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import <Foundation/Foundation.h>

#import "Vehicle.h"
#import "RouteWaypoints.h"

@interface Route : NSObject

@property (nonatomic, assign) NSNumber *id;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *shortName;
@property (nonatomic, assign) BOOL fare;
@property (nonatomic, strong) NSString *desc;

@property (nonatomic, strong) NSArray<Vehicle*> *vehicles;
@property (nonatomic, strong) RouteWaypoints *waypoints;

@end
