//
//  Arrival.m
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import "Arrival.h"

@implementation Arrival

- (NSString *)description {
    return [NSString stringWithFormat:@"Bus %@ in %@ seconds", self.vehicleName, self.secondsToArrival];
}

@end
