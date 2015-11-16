//
//  RouteDefinitionAndVehiclesDAO.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteDefinitionDAO.h"

@implementation RouteDefinitionDAO

-(id) initWithStopID:(int) stopSetID
{
    self = [super init];
    if (self) {
        //initializations
        routeDefinitionData = [[[RouteDefinitionPost alloc] initWithStopSet:stopSetID] processResponse];
    }
    return self;
}

-(NSArray*) getRoutePoints
{
    return [routeDefinitionData objectAtIndex:0];
}

-(NSArray*) getRouteStops
{
    return [routeDefinitionData objectAtIndex:1];
}

@end
