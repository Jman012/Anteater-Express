//
//  StopArrivalPredictionPost.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StopArrivalPredictionPost.h"

@implementation StopArrivalPredictionPost

@synthesize stopSetID;
@synthesize stopID;

-(id) initWithRouteStopSetID: (int) stopSetIDInt andStopID: (int) stopIDInt
{
    if(self = [super init])
    {
        [self setStopSetID:stopSetIDInt];
        [self setStopID:stopIDInt];
    }
    
    return self;
}

- (NSArray*) processResponse
{
    
    NSMutableArray* pairs = [[NSMutableArray alloc] init];
    
    [pairs addObject:[[NameValuePair alloc] initWithName:@"EntityTypeParam" andValue:@"STOP_ARRIVAL_PREDICTIONS"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"PayloadFormatParam" andValue:@"JSON"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"StopSetIdParam" andValue:[NSString stringWithFormat:@"%i", stopSetID]]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"StopIdParam" andValue:[NSString stringWithFormat:@"%i", stopID]]];
    
    HttpPostExecute* post = [[HttpPostExecute alloc] init]; 
    
    [post sendRequest:@"http://apps.shuttle.uci.edu:8081/AE_Data_Service/DataAccessServlet" withNameValuePairs:pairs];
    
    
    NSData* data = [post responseData];
    
    if([data length] <= 0)
    {
        NSLog(@"Stop Arrival Predictions returned no data");
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
