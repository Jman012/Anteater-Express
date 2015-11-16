//
//  StopArrivalPredictionDAO.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StopArrivalPredictionPost.h"

@interface StopArrivalPredictionDAO : NSObject
{
    NSArray* stopArrivalPredictionsData;
}

-(id) initWithStopSetID:(int) stopSetID andStopID:(int) stopID;

-(NSArray*) getArrivalTimes;

@end
