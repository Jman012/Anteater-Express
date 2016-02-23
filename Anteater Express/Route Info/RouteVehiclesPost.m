//
//  RouteVehiclesPost.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteVehiclesPost.h"

@implementation RouteVehiclesPost

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
    
    [pairs addObject:[[NameValuePair alloc] initWithName:@"EntityTypeParam" andValue:@"ROUTE_VEHICLES"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"PayloadFormatParam" andValue:@"JSON"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"StopSetIdParam" andValue:[NSString stringWithFormat:@"%i", stopSetID]]];
    
    HttpPostExecute* post = [[HttpPostExecute alloc] init]; 
    
    [post sendRequest:@"http://apps.shuttle.uci.edu:8081/AE_Data_Service/DataAccessServlet" withNameValuePairs:pairs];
    
    
    NSData* data = [post responseData];
    
    // NSLog(@"ROUTEVEHICLESPOST");
    
    if([data length] <= 0)
    {
        NSLog(@"Route Vehicles returned no data");
        return nil;
    }
    else
    {
        // NSLog(@"Data Size: %@",[[NSNumber numberWithUnsignedInteger:[data length]] stringValue]);
        
        NSError* e = nil;
        NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        /*for(NSMutableDictionary *item in jsonData)
        {
            NSLog(@"Data Content:  %@", item );
        }*/
        return jsonData;
    }
}

@end
