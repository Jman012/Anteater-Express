//
//  RouteVehiclesDAO.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteVehiclesDAO.h"

@implementation RouteVehiclesDAO

-(id) initWithStopID:(int) stopSetID
{
    self = [super init];
    if (self) {
        //initializations
        routeVehiclesData = [[[RouteVehiclesPost alloc] initWithStopSet:stopSetID] processResponse];
    }
    return self;
}

-(NSArray*) getRouteVehicles
{
    return routeVehiclesData; 
}

@end
