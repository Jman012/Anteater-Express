//
//  RouteDefinitionPost.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteDefinitionPost.h"

@implementation RouteDefinitionPost

@synthesize stopSetID;

-(id) initWithStopSet: (int) stopSetIDInt
{
    if(self = [super init])
    {
        [self setStopSetID:stopSetIDInt];
    }
    
    return self;
}

- (NSArray*) processResponse
{
    
    NSMutableArray* pairs = [[NSMutableArray alloc] init];
    
    [pairs addObject:[[NameValuePair alloc] initWithName:@"EntityTypeParam" andValue:@"ROUTE_DEFINITION"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"PayloadFormatParam" andValue:@"JSON"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"StopSetIdParam" andValue:[NSString stringWithFormat:@"%i",stopSetID]]];
    
   // NSLog(@"Stop Set ID: %i", stopSetID);
    
    HttpPostExecute* post = [[HttpPostExecute alloc] init]; 
    
    [post sendRequest:@"http://apps.shuttle.uci.edu:8080/AE_Data_Service/DataAccessServlet" withNameValuePairs:pairs];
    
    /*for(NameValuePair *item in pairs)
    {
        NSLog(@"Data Content:  %@  %@", [item name], [item value]);
    }*/
    
    NSData* data = [post responseData];
    
   // NSLog(@"ROUTEDEFINITIONPOST");
    
    if([data length] <= 0)
    {
        NSLog(@"Route Definitions returned no data");
        return nil;
    }
    else
    {
        //NSLog(@"Data Size: %@",[[NSNumber numberWithUnsignedInteger:[data length]] stringValue]);
        
        NSError* e = nil;
       /* NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        NSLog(@"Array Size  %i", [jsonData count]);
        
        for(NSMutableDictionary *item in jsonData)
        {
            NSLog(@"Data Content:  %@", item );
        }*/
        
       NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        
        //Spit out Error Text
       // NSString * details = [[e userInfo] objectForKey: @"NSDebugDescription"];
       // NSLog(@" %@", details);
        
        if(!jsonData)
            NSLog(@"JSON PARSER FAILED: ROUTE DEFINITION POST");
        
        if(![jsonData isKindOfClass:[NSArray class]])
            NSLog(@"JSON PARSER HAS NOT RETURNED A DICTIONARY: ROUTE DEFINITION POST");
        
      /*  NSArray *routePoints = [jsonData objectAtIndex:0];
        
       // NSLog(@"Size of Route Point %i", [routePoints count]);
        
        NSArray *routeStops = [jsonData objectAtIndex:1];
        
        for(NSMutableDictionary *routePoint in routePoints)
        {
            NSLog(@"Data Content:  %@", routePoint);
        }
        
        NSLog(@"ARRAY 2 STARTS:");
            
        for(NSMutableDictionary *routePoint in routeStops)
        {
            NSLog(@"Data Content:  %@", routePoint);
        }*/
        
        
         //NSLog(@"Array Size  %i", [jsonData count]);
       /* NSArray* routePoints = [jsonData objectForKey:@"routePoints"];
        for(NSMutableDictionary *item in routePoints)
        {
            NSLog(@"Data Content:  %@", item);
        }*/
        
        return jsonData;
    }
}

@end
