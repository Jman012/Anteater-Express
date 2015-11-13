//
//  HttpPostExecute.m
//  NSHttpPost
//
//  Created by Andrew Beier on 2/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import "HttpPostExecute.h"
#import "NameValuePair.h"
#define SC_INTERNALS_SERVER_ERROR 500

NSTimeInterval const CONNECTION_TIMEOUT = 110;
NSString* servletURL;

@implementation HttpPostExecute

@synthesize responseData = _responseData;

/*- (id) initWithURL: (NSString *) url withNameValuePairs: (NSObject) obj 
 send a list of NameValuePairs
 {
 self = [super init];
 if(self)
 {
 httpResponse = [[NSMutableArray alloc] init];
 servletURL = url;
 
 }
 */
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
	//NSMutableString* requestURL = [[NSMutableArray alloc] init];
	//[requestURL appendString:url];
	//NSLog(@"Here: At sendRequest beginning");
	NSMutableString* body = [[NSMutableString alloc] init];
	int size = [array count];
	
	for(int i=0 ; i < size; i++)
	{
        //NSLog(@"NameValuePair: %@, %i", [[array objectAtIndex:i] name], i);
        NameValuePair* pair =[array objectAtIndex:i];
        if(i != 0)
        {
            [body appendString:@"&"];
        }
        [body appendString:[pair name]];
        [body appendString:@"="];
        [body appendString:[self urlEncodeValue:[pair value]]];
        //[body appendString:[pair value]];
    }
    
  //  NSLog(@"URL: %@%@", url, body);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSString* requestBody = [NSString stringWithString:body];
    NSData *data = [NSData dataWithBytes:[requestBody UTF8String] length:[requestBody length]];
   // NSLog(@"Here: Setting HTTP Post request");
    [request setHTTPMethod: @"POST"];
    [request setTimeoutInterval:CONNECTION_TIMEOUT];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody: data];
  //  NSLog(@"Here: Finished Setting HTTP Post Request");
    //id i = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self setResponseData:[NSURLConnection sendSynchronousRequest:request returningResponse:nil error: nil]];
//    if (i == nil || i == NULL)
//    {
//        NSLog(@"Connection not initialized");
//    }
  //  NSLog(@"End of sendRequest");
}	

- (NSString *)urlEncodeValue:(NSString *)str
{
    //NSLog(@"Encoding Values");
    NSString *result = (__bridge_transfer NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge_retained CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
    return result;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // [httpResponse setLength:0];
    NSLog(@"didRecieveResponse");
    NSMutableString* string = [[NSMutableString alloc] init];
    [string appendString:@"\nexpectedContentLength: "];
    [string appendString:[[NSNumber numberWithLong:[response expectedContentLength]] stringValue]];
    [string appendString:@"\nURL: "];
    [string appendString: [[response URL] absoluteString]];
    NSLog(@"%@",string);
   
    
}

// Called when data has been received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"didRecieveData");
    if([data length] <= 0)
    {
        NSLog(@"Sadface, no data");
    }
    else
    {
      //  NSLog([data description]);
        NSLog(@"%@",[[NSNumber numberWithUnsignedInteger:[data length]] stringValue]);
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", newStr);
        [_responseData appendData:data];
        [self setResponseData:_responseData];
        
       // NSData *theJSONData = /* some JSON data */
        //NSError *theError = nil;
        //id theObject = [[CJSONDeserializer deserializer] deserialize:theJSONData error:&theError];}
        
        // sets the responseData property with the contents of the HTTP Response
        //[httpResponse appendData:data];
        
    }
  
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString* responseString = [[[NSString alloc] initWithData:[self responseData] encoding:NSUTF8StringEncoding] copy];
    NSLog(@"%@", responseString);
    NSLog(@"Here: connectionDidFinishLoading");
    // Do something with the response
}

// TODO: ADD connection did fail with error

@end



