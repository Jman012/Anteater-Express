//
//  RoutesPost.h
//  NSHttpPost
//
//  Created by Andrew Beier on 4/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpPostExecute.h"
#import "NameValuePair.h"

@interface RoutesPost : NSObject
{}
- (NSArray*) processResponse;
@end
