//
//  StopArrivalPredictionPost.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpPostExecute.h"
#import "NameValuePair.h"

@interface StopArrivalPredictionPost : NSObject
{}

@property (assign, nonatomic) int stopSetID;
@property (assign, nonatomic) int stopID;

- (NSArray*) processResponse;

-(id) initWithRouteStopSetID: (int) stopSetID andStopID: (int) stopID;

@end
