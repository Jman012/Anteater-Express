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

@property (nonatomic, strong) void (^returnBlock)(NSArray<StopArrivalPredictionDAO *> *stopArrivalPredictionsDAOs);

- (instancetype)initWithStopSetIds:(NSArray<NSNumber *> *)theStopSetIds stopIds:(NSArray<NSNumber *> *)theStopIds;

@end
