//
//  RoutesDAO.m
//  NSHttpPost
//
//  Created by Andrew Beier on 4/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import "RoutesAndAnnounceDAO.h"

@implementation RoutesAndAnnounceDAO

- (id)init {
    self = [super init];
    if (self) {
        //initializations
        routeData = [[[RoutesPost alloc] init] processResponse];
        announceData = [[[AnnouncementsPost alloc] init] processResponse];
    }
    return self;
}

-(NSArray*) getRoutes
{
    return routeData;
}

-(NSArray*) getServiceAnnouncements
{
    return announceData; 
}
@end
