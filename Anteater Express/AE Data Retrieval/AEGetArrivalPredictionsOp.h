//
//  AEGetArrivalPredictionsOp.h
//  Anteater Express
//
//  Created by James Linnell on 1/14/16.
//
//

#import <Foundation/Foundation.h>

#import "StopArrivalPredictionDAO.h"

@interface AEGetArrivalPredictionsOp : NSOperation

@property (nonatomic, strong) void (^returnBlock)(StopArrivalPredictionDAO *stopArrivalPredictionsDAO);

- (instancetype)initWithStopSetId:(NSInteger)theStopSetId stopId:(NSInteger)theStopId;

@end
