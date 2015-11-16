//
//  RouteSchedulesDAO.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteSchedulesPost.h"

@interface RouteSchedulesDAO : NSObject
{
    NSArray* routeScheduleData;
}

-(id) initWithRouteName:(NSString*) routeNamePassed;

-(NSArray*) getRouteSchedulesRawData;

-(NSArray*) getStopScheduledTimes: (int) stopID;

-(NSArray*) getRouteStops;

@end
