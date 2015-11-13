//
//  AnnouncementsPost.m
//  AnteaterExpress
//
//  Created by Andrew Beier on 5/5/12.
//  Copyright (c) 2012 Anteater Express. All rights reserved.
//

#import "AnnouncementsPost.h"

@implementation AnnouncementsPost

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
    
    [pairs  addObject:[[NameValuePair alloc] initWithName:@"EntityTypeParam" andValue:@"SERVICE_ALERTS"]];
    [pairs addObject:[[NameValuePair alloc] initWithName:@"PayloadFormatParam" andValue:@"JSON"]];
    
    HttpPostExecute* post = [[HttpPostExecute alloc] init]; 
    
    [post sendRequest:@"http://apps.shuttle.uci.edu:8080/AE_Data_Service/DataAccessServlet" withNameValuePairs:pairs];
    
    
    NSData* data = [post responseData];
    
  //  NSLog(@"ANNOUNCEMENTSPOST");
    
    if([data length] <= 0)
    {
        NSLog(@"Announcements returned no data");
        return nil;
    }
    else
    {
      //  NSLog(@"Data Size: %@",[[NSNumber numberWithUnsignedInteger:[data length]] stringValue]);
        
        NSError* e = nil;
        NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        /*for(NSMutableDictionary *item in jsonData)
        {
            
           // NSLog(@"Data Content:  %@", item );
        }*/
        return jsonData;
    }
}
@end

