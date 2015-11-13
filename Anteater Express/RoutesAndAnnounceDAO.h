//
//  RoutesDAO.h
//  NSHttpPost
//
//  Created by Andrew Beier on 4/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RoutesPost.h"
#import "AnnouncementsPost.h"

@interface RoutesAndAnnounceDAO : NSObject
{
   // RoutesPost* routePost;
    NSArray* routeData;
    
   // AnnouncementsPost* announcePost;
    NSArray* announceData;
}

-(NSArray*) getRoutes;
-(NSArray*) getServiceAnnouncements;

@end
