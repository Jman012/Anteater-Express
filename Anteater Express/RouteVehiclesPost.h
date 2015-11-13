//
//  RouteVehiclesPost.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpPostExecute.h"
#import "NameValuePair.h"

@interface RouteVehiclesPost : NSObject
{
}

@property (assign, nonatomic) int stopSetID;

- (NSArray*) processResponse;

-(id) initWithStopSet: (int) stopSetID;

@end
