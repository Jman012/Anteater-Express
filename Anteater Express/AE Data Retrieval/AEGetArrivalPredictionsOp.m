//
//  AEGetArrivalPredictionsOp.m
//  Anteater Express
//
//  Created by James Linnell on 1/14/16.
//
//

#import "AEGetArrivalPredictionsOp.h"

@interface AEGetArrivalPredictionsOp ()

@property (nonatomic, strong) NSArray<NSNumber *> *stopSetIds;
@property (nonatomic, strong) NSArray<NSNumber *> *stopIds;

@end

@implementation AEGetArrivalPredictionsOp

- (instancetype)initWithStopSetIds:(NSArray<NSNumber *> *)theStopSetIds stopIds:(NSArray<NSNumber *> *)theStopIds {
    if (self = [super init]) {
        if (theStopSetIds.count != theStopIds.count) {
            return nil;
        }
        
        self.stopSetIds = [NSArray arrayWithArray:theStopSetIds];
        self.stopIds = [NSArray arrayWithArray:theStopIds];
    }
    return self;
}

- (void)main {
    
    NSMutableArray<StopArrivalPredictionDAO *> *daos = [NSMutableArray array];
    
    for (int i = 0; i < self.stopSetIds.count; ++i) {
        int stopSetId = self.stopSetIds[i].intValue;
        int stopId = self.stopIds[i].intValue;
        
        // Instantiating this will perform the network request
        NSLog(@"Good getting preds stopsetid=%d, stopid=%d", stopSetId, stopId);
        StopArrivalPredictionDAO *stopArrivalPredictions = [[StopArrivalPredictionDAO alloc] initWithStopSetID:stopSetId andStopID:stopId];
        [daos addObject:stopArrivalPredictions];
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^() {
        self.returnBlock(daos);
    });
}

@end
