//
//  RouteUpdatesDAO.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteUpdatesPost.h"

@interface RouteUpdatesDAO : NSObject
{
    NSMutableArray* originalRouteUpdatesData;
    NSArray* routeUpdatesData;
}

-(id) initWithRouteName:(NSString*) routeNamePassed;

-(NSArray*) getRouteUpdates;

@end
