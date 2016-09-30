//
//  RoutesPost.m
//  NSHttpPost
//
//  Created by Andrew Beier on 4/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import "RoutesPost.h"

@implementation RoutesPost

- (id)init {
    self = [super init];
    if (self) {
        //initializations.
    }
    return self;
}

- (NSArray*) processResponse
{
   
    NSMutableArray* pairs = [[NSMutableArray alloc] init];
    
    [pairs  addObject:[[NameValuePair alloc] initWithName:@"EntityTypeParam" andValue:@"ROUTES"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"PayloadFormatParam" andValue:@"JSON"]];
    
    HttpPostExecute* post = [[HttpPostExecute alloc] init]; 
    
    [post sendRequest:@"http://apps.anteaterexpress.com:8080/AE_Data_Service/DataAccessServlet" withNameValuePairs:pairs];

    
    NSData* data = [post responseData];

   // NSLog(@"ROUTESPOST");
    
    if([data length] <= 0)
    {
        NSLog(@"Routes returned no data");
        return nil;
    }
    else
    {
       // NSLog(@"Data Size: %@",[[NSNumber numberWithUnsignedInteger:[data length]] stringValue]);
        
        NSError* e = nil;
        NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
       /* for(NSMutableDictionary *item in jsonData)
        {
        
            NSLog(@"Data Content:  %@", item );
        }*/
        return jsonData;
    }
}
@end
