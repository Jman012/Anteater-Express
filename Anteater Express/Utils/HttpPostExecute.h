//
//  HttpPostExecute.h
//  NSHttpPost
//
//  Created by Andrew Beier on 2/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HttpPostExecute : NSObject
//and multiple name value pairs
{
    //add http response data 
@protected
    NSMutableData* _responseData;
}
//add sendRequest method declaration here
-(void) sendRequest: (NSString *) url withNameValuePairs:(NSMutableArray*) array;

- (NSString *)urlEncodeValue:(NSString *)str;
//property for NSData responseData;
@property (nonatomic, retain) NSData* responseData;

@end
