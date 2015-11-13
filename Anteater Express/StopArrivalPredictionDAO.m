//
//  StopArrivalPredictionDAO.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StopArrivalPredictionDAO.h"

@implementation StopArrivalPredictionDAO

-(id) initWithStopSetID:(int) stopSetID andStopID:(int) stopID
{
    self = [super init];
    if (self) {
        //initializations
        stopArrivalPredictionsData = [[[StopArrivalPredictionPost alloc] initWithRouteStopSetID:stopSetID andStopID:stopID] processResponse];
    }
    return self;
}

-(NSArray*) getArrivalTimes
{
    return stopArrivalPredictionsData; 
}

@end
