//
//  RouteVehiclesDAO.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteVehiclesPost.h"

@interface RouteVehiclesDAO : NSObject
{
    // RouteVehiclesPost* routeVehiclesPost;
    NSArray* routeVehiclesData;
}

-(id) initWithStopID:(int) stopSetID;

-(NSArray*) getRouteVehicles;

@end
