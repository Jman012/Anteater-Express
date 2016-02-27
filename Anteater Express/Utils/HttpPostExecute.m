//
//  HttpPostExecute.m
//  NSHttpPost
//
//  Created by Andrew Beier on 2/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import "HttpPostExecute.h"
#import "NameValuePair.h"
#import "AENetwork.h"
#define SC_INTERNALS_SERVER_ERROR 500

NSTimeInterval const CONNECTION_TIMEOUT = 110;
NSString* servletURL;

@implementation HttpPostExecute

@synthesize responseData = _responseData;


- (id) init
{
    self = [super init];
	if(self)
	{
		_responseData = [[NSMutableData alloc] init];
       // NSLog(@"Here! at init");
        
	}
    return self;
}

-(void) sendRequest: (NSString *) url withNameValuePairs:(NSMutableArray*) array
{

	NSMutableString* body = [[NSMutableString alloc] init];
	NSUInteger size = [array count];
	
	for(NSUInteger i = 0; i < size; i++)
	{
        NameValuePair* pair =[array objectAtIndex:i];
        if(i != 0)
        {
            [body appendString:@"&"];
        }
        [body appendString:[pair name]];
        [body appendString:@"="];
        [body appendString:[self urlEncodeValue:[pair value]]];
    }
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSString* requestBody = [NSString stringWithString:body];
    NSData *data = [NSData dataWithBytes:[requestBody UTF8String] length:[requestBody length]];

    [request setHTTPMethod: @"POST"];
    [request setTimeoutInterval:CONNECTION_TIMEOUT];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody: data];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                [[NSNotificationCenter defaultCenter] postNotificationName:AENetworkInternetError object:AENetworkInternetError];
            });
            dispatch_semaphore_signal(semaphore);
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode != 200) {
                dispatch_async(dispatch_get_main_queue(), ^() {
                    [[NSNotificationCenter defaultCenter] postNotificationName:AENetworkServerError object:AENetworkServerError];
                });
                dispatch_semaphore_signal(semaphore);
                return;
            }
        }
        
        [self setResponseData:data];
        dispatch_async(dispatch_get_main_queue(), ^() {
            [[NSNotificationCenter defaultCenter] postNotificationName:AENetworkOk object:AENetworkOk];
        });
        dispatch_semaphore_signal(semaphore);
        return;
        
    }];
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}	

- (NSString *)urlEncodeValue:(NSString *)str
{
    //NSLog(@"Encoding Values");
    NSString *result = (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge_retained CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
    return result;
}

@end