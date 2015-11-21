//
//  RouteSchedulesPost.ms
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 Anteater Express. All rights reserved.
//

#import "RouteSchedulesPost.h"

@implementation RouteSchedulesPost

NSString *routeName_routeSchedulesPost;

- (id)initWithRouteName: (NSString*) routeNamePassed {
self = [super init];
if (self) {
    //initializations.
    routeName_routeSchedulesPost = routeNamePassed;
}
return self;
}

- (NSArray*) processResponse
{

    NSMutableArray* pairs = [[NSMutableArray alloc] init];

    [pairs addObject:[[NameValuePair alloc] initWithName:@"EntityTypeParam" andValue:@"ROUTE_SCHEDULES"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"PayloadFormatParam" andValue:@"JSON"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"RouteNameParam" andValue:[NSString stringWithFormat:@"%@",routeName_routeSchedulesPost]]];
        
    HttpPostExecute* post = [[HttpPostExecute alloc] init]; 

    [post sendRequest:@"http://apps.shuttle.uci.edu:8080/AE_Data_Service/DataAccessServlet" withNameValuePairs:pairs];


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
        
        return jsonData;
    }
}


@end