//
//  Arrival.h
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import <Foundation/Foundation.h>

@interface Arrival : NSObject

@property (nonatomic, strong) NSNumber *vehicleID;
@property (nonatomic, strong) NSString *vehicleName;
@property (nonatomic, strong) NSNumber *secondsToArrival;

@end
