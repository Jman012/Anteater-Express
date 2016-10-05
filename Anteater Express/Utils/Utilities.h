//
//  Utilities.h
//  Anteater Express
//
//  Created by Andrew Beier on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define VIEWED_ROUTE_UPDATES @"viewedRouteUpdates"
//#define VIEWED_ANNOUNCEMENTS @"viewedAnnouncments"

extern NSString* const VIEWED_ROUTE_UPDATES;
extern NSString* const VIEWED_ANNOUNCEMENTS;

@interface Utilities : NSObject

+ (NSString *) dateDisplayString: (NSString *) dateFromJson;
+ (NSString *)dateDisplayStringFromDate:(NSDate *)date;
+ (int) getCurrentDayOfWeek;
@end
