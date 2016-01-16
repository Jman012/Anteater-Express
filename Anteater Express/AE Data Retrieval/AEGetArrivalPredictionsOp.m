//
//  AEGetArrivalPredictionsOp.m
//  Anteater Express
//
//  Created by James Linnell on 1/14/16.
//
//

#import "AEGetArrivalPredictionsOp.h"

@interface AEGetArrivalPredictionsOp ()

@property (nonatomic, assign) NSInteger stopSetId;
@property (nonatomic, assign) NSInteger stopId;

@end

@implementation AEGetArrivalPredictionsOp

- (instancetype)initWithStopSetId:(NSInteger)theStopSetId stopId:(NSInteger)theStopId {
    if (self = [super init]) {
        self.stopSetId = theStopSetId;
        self.stopId = theStopId;
    }
    return self;
}

- (void)main {
    
    // Instantiating this will perform the network request
    StopArrivalPredictionDAO *stopArrivalPredictions = [[StopArrivalPredictionDAO alloc] initWithStopSetID:(int)self.stopSetId andStopID:(int)self.stopId];
    
    dispatch_sync(dispatch_get_main_queue(), ^() {
        self.returnBlock(stopArrivalPredictions);
    });
}

@end
