//
//  Utilities.m
//  Anteater Express
//
//  Created by Andrew Beier on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Utilities.h"
#import <arpa/inet.h>

#import "Reachability.h"

@implementation Utilities

NSString* const VIEWED_ROUTE_UPDATES = @"viewedRouteUpdates";
NSString* const VIEWED_ANNOUNCEMENTS = @"viewedAnnouncements";

+(NSInteger) checkNetworkStatus
{
    NSInteger returnValue = 0;
    //NSString *serverIP = @"apps.shuttle.uci.edu";
    //const char *serverIPChar = [serverIP cStringUsingEncoding:NSASCIIStringEncoding];
    
    //struct sockaddr_in address;
    //address.sin_len = sizeof(address);
    //address.sin_family = AF_INET;
    //address.sin_port = htons(8081);
    //address.sin_addr.s_addr = inet_addr("128.200.237.7");
    
    Reachability* internetReachable = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
            //NSLog(@"The internet is down.");
            returnValue = 1;
            break;
        }
        case ReachableViaWiFi:
        {
            //NSLog(@"The internet is working via WIFI.");
            returnValue = 0;
            
            break;
        }
        case ReachableViaWWAN:
        {
            //NSLog(@"The internet is working via WWAN.");
            returnValue = 0;
            
            break;
        }
    }
    if (returnValue == 0) {
        NSString *connected = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://apps.shuttle.uci.edu:8081/"] encoding: NSUTF8StringEncoding error:nil];
        
        //NSLog(@"checking connection");
        if(connected == NULL)
        {
            returnValue = 2;
        }
    }
    return returnValue;
}

+ (NSString *)dateDisplayStringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMM d, yyy hh:mm:ss a";
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"PDT"];
    return [Utilities dateDisplayString:[formatter stringFromDate:date]];
}

+ (NSString *) dateDisplayString: (NSString *) dateFromJson
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, yyyy hh:mm:ss a"];
    
    NSDate *dateToFormat = [formatter dateFromString:dateFromJson];
    
    double secondsInterval = [dateToFormat timeIntervalSinceNow] * -1;
    int daysDiff = round (secondsInterval/(60*60*24));
    
    if(secondsInterval < 60) // seconds
    {
        return [NSString stringWithFormat:@"%d seconds ago", (int) secondsInterval];
    }
    else if(secondsInterval < 3600) // minutes
    {
        int minutes = round(secondsInterval/60);
        
        return [NSString stringWithFormat:@"%d %@ ago",minutes, (minutes == 1? @"minute" : @"minutes")];
    }
    else if(daysDiff == 0) // if it's Today
    {
        [formatter setDateFormat:@"h:mm a"];
        return [formatter stringFromDate:dateToFormat];
    }
    else if(daysDiff == 1)
    {
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setDoesRelativeDateFormatting:YES];
        return [formatter stringFromDate:dateToFormat];
    }
    else if(daysDiff < 7 && daysDiff >= 2)
    {
        return [NSString stringWithFormat:@"%d days ago",daysDiff];
    }
    else {
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        return [formatter stringFromDate:dateToFormat];
    }
}

+ (int) getCurrentDayOfWeek
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init] ;
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"EEEE"];
    NSString *dayName = [dateFormatter stringFromDate:[NSDate date]];
    if ([dayName isEqualToString:@"Monday"]) {
        return 1;
    }
    else if ([dayName isEqualToString:@"Tuesday"])
    {
        return 2;
    }
    else if ([dayName isEqualToString:@"Wednesday"])
    {
        return 3;
    }
    else if ([dayName isEqualToString:@"Thursday"])
    {
        return 4;
    }
    else if ([dayName isEqualToString:@"Friday"])
    {
        return 5;
    }
    else if ([dayName isEqualToString:@"Saturday"])
    {
        return 6;
    }
    else //sunday
    {
        return 0;
    }
}

@end
