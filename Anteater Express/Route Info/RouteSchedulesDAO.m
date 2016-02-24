//
//  RouteSchedulesDAO.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteSchedulesDAO.h"

@implementation RouteSchedulesDAO

-(id) initWithRouteName:(NSString *) routeNamePassed
{
    self = [super init];
    if (self) {
        //initializations
        routeScheduleData = [[[RouteSchedulesPost alloc] initWithRouteName:routeNamePassed] processResponse];
    }
    return self;
}

-(NSArray*) getRouteSchedulesRawData
{
    return routeScheduleData;
}

-(NSArray*) getStopScheduledTimes: (int) stopID
{
    NSMutableArray* routeSchedulesForStop = [[NSMutableArray alloc] init];
    
    for(int j = 0; j < routeScheduleData.count; j++) //Go through all Route Schedules
    {
        NSMutableDictionary* tempRouteSchedule = [[NSMutableDictionary alloc] init];
        
        //Add Route Schedule Name to Dictionary
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ScheduleName"] forKey:@"ScheduleName"];
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ServiceSun"] forKey:@"ServiceSun"];
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ServiceMon"] forKey:@"ServiceMon"];
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ServiceTue"] forKey:@"ServiceTue"];
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ServiceWed"] forKey:@"ServiceWed"];
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ServiceThu"] forKey:@"ServiceThu"];
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ServiceFri"] forKey:@"ServiceFri"];
        [tempRouteSchedule setObject:[[routeScheduleData objectAtIndex:j] valueForKey:@"ServiceSat"] forKey:@"ServiceSat"];
        
        NSArray* tempRouteScheduleArrayOfScheduledStops = [[routeScheduleData objectAtIndex:j] valueForKey:@"ScheduledStops"];
        
        //Go through all scheduled Stops in route schedule and add in only ones of the stopID passed in
        for (int i = 0; i < tempRouteScheduleArrayOfScheduledStops.count; i++) 
        {
            if([[[tempRouteScheduleArrayOfScheduledStops objectAtIndex:i] valueForKey:@"StopId"] intValue] == stopID) //If the requested stopID passed in matches this stop in the array of stops then add its information into the to be returned array
            {
                NSMutableDictionary* tempStopDict = [[NSMutableDictionary alloc] init];
                
                tempStopDict = [[tempRouteScheduleArrayOfScheduledStops objectAtIndex:i] valueForKey:@"Stop"];
                [tempStopDict setObject:[[tempRouteScheduleArrayOfScheduledStops objectAtIndex:i] valueForKey:@"StopNumber"] forKey:@"StopNumber"];
                [tempStopDict setObject:[[tempRouteScheduleArrayOfScheduledStops objectAtIndex:i] valueForKey:@"TimedStop"] forKey:@"TimedStop"];
                [tempStopDict setObject:[[tempRouteScheduleArrayOfScheduledStops objectAtIndex:i] valueForKey:@"RouteScheduleId"] forKey:@"RouteScheduleId"];
                
                //Sort the NSArray inside NSMutableDictionary of departure times in accending order
                NSSortDescriptor * departureOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"DepartureTime" ascending:YES];
                
                NSArray * descriptors = [NSArray arrayWithObjects:departureOrderDescriptor, nil];
                NSArray * sortedTimes = [[[tempRouteScheduleArrayOfScheduledStops objectAtIndex:i] valueForKey:@"ScheduledTimes"] sortedArrayUsingDescriptors:descriptors];
                
                //Added the sorted times dictionary into the return result
                [tempStopDict setObject:sortedTimes forKey:@"ScheduledTimes"];
                
                
                [tempRouteSchedule setObject:tempStopDict forKey:@"StopDetails"];
                break; //Breaks out once it found the correct stop and looks through the next route schedule
            }
        }
        
        [routeSchedulesForStop addObject:tempRouteSchedule];
        
    }
    
    //NSLog(@"%@", [routeScheduleData valueForKey:@"ScheduledStops"]);
    NSArray *arrayToBeReturned = [[NSArray alloc] initWithArray:routeSchedulesForStop];
    return arrayToBeReturned;
}

-(NSArray*) getRouteStops
{
    NSMutableArray* stops = [[NSMutableArray  alloc] init];
    NSMutableSet* uniqueStopSet = [[NSMutableSet alloc] init];
    
    for(int j = 0; j < routeScheduleData.count; j++) //Go through all Route Schedules
    {
        NSArray* scheduledStops = [[routeScheduleData objectAtIndex:j] valueForKey:@"ScheduledStops"];
        //Go through all scheduled Stops in route schedule
        for (int i = 0; i < scheduledStops.count; i++) 
        {
            NSMutableDictionary* stopDict = [[NSMutableDictionary alloc] init];
            stopDict = [[scheduledStops objectAtIndex:i] valueForKey:@"Stop"];
            [stopDict setObject:[[scheduledStops objectAtIndex:i] valueForKey:@"StopNumber"] forKey:@"StopNumber"];
            [stopDict setObject:[[scheduledStops objectAtIndex:i] valueForKey:@"TimedStop"] forKey:@"TimedStop"];
            //[stopDict setObject:[[scheduledStops objectAtIndex:i] valueForKey:@"ScheduledTimes"] forKey:@"ScheduledTimes"];
            
            
            if(![uniqueStopSet containsObject:[[scheduledStops objectAtIndex:i] valueForKey:@"StopId"]])
            {
                [stops addObject:stopDict];
                [uniqueStopSet addObject:[[scheduledStops objectAtIndex:i] valueForKey:@"StopId"]];
            }
        }
        
    }
    
    //Sort the final NSMutableArray into a NSArray to be returned in order of Stop Number
    NSSortDescriptor * stopOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"StopNumber" ascending:YES];
    //id obj;
    //NSEnumerator * enumerator = [stops objectEnumerator];
    //while ((obj = [enumerator nextObject])) NSLog(@"%@", obj);
    NSArray * descriptors = [NSArray arrayWithObjects:stopOrderDescriptor, nil];
    NSArray * sortedStops = [stops sortedArrayUsingDescriptors:descriptors];
    /*NSLog(@"\nSorted . . . ");
    enumerator = [sortedStops objectEnumerator];
    while((obj = [enumerator nextObject])) NSLog(@"%@", obj);*/
    
    return sortedStops;
}

@end
