//
//  RouteDefinitionAndVehiclesDAO.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteDefinitionPost.h"

@interface RouteDefinitionDAO : NSObject
{
    // RouteDefinitionPost* routeDefinitionPost;
    NSArray* routeDefinitionData;
}

-(id) initWithStopID:(int) stopSetID;

-(NSArray*) getRoutePoints;
-(NSArray*) getRouteStops;

@end
