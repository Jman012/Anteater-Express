//
//  RouteUpdatesPost.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 Anteater Express. All rights reserved.
//

#import "RouteUpdatesPost.h"

@implementation RouteUpdatesPost

NSString *routeName_updatesPost;

- (id)initWithRouteName: (NSString*) routeNamePassed {
    self = [super init];
    if (self) {
        //initializations.
        routeName_updatesPost = routeNamePassed;
    }
    return self;
}

- (NSArray*) processResponse
{
    
    NSMutableArray* pairs = [[NSMutableArray alloc] init];
    
    [pairs  addObject:[[NameValuePair alloc] initWithName:@"EntityTypeParam" andValue:@"ROUTE_ALERTS"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"PayloadFormatParam" andValue:@"JSON"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"RouteNameParam" andValue:[NSString stringWithFormat:@"%@",routeName_updatesPost]]];
    
    HttpPostExecute* post = [[HttpPostExecute alloc] init]; 
    
    [post sendRequest:@"http://apps.anteaterexpress.com:8080/AE_Data_Service/DataAccessServlet" withNameValuePairs:pairs];
    
    
    NSData* data = [post responseData];
    
    if([data length] <= 0)
    {
        NSLog(@"Route Updates returned no data");
        return nil;
    }
    else
    {
        NSError* e = nil;
        NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        
        /*for(NSMutableDictionary *routeUpdate in jsonData)
        {
            NSLog(@"Data Content:  %@", routeUpdate);
        }*/
        
        return jsonData;
    }
}


@end
