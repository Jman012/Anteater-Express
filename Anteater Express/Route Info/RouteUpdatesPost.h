//
//  RouteUpdatesPost.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpPostExecute.h"
#import "NameValuePair.h"

@interface RouteUpdatesPost : NSObject
{}

- (NSArray*) processResponse;

-(id) initWithRouteName: (NSString*) routeNamePassed;

@end
