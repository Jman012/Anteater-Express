//
//  RouteUpdatesDAO.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteUpdatesDAO.h"

@implementation RouteUpdatesDAO

-(id) initWithRouteName:(NSString *) routeNamePassed
{
    self = [super init];
    if (self) {
        //initializations
        routeUpdatesData = [[[RouteUpdatesPost alloc] initWithRouteName:routeNamePassed] processResponse];
        originalRouteUpdatesData = [[[[RouteUpdatesPost alloc] initWithRouteName:routeNamePassed] processResponse] mutableCopy];
        
        for (NSMutableDictionary *update in originalRouteUpdatesData)
        {
            if([[update valueForKey:@"RouteAlertExpired"] boolValue])
            {
                NSLog(@"%s", "EXPIRED");
                [originalRouteUpdatesData removeObject:update];
            }
            NSLog(@"%@", [update valueForKey:@"RouteAlertPostUntil"]);
        }
    }
    return self;
}

-(NSArray*) getRouteUpdates
{
    return routeUpdatesData;
}


@end
