//
//  Vehicle.h
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import <Foundation/Foundation.h>

@interface Vehicle : NSObject

@property (nonatomic, assign) NSNumber *id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *updated;
@property (nonatomic, strong) NSString *updatedAgo;
@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSNumber *speed;
@property (nonatomic, strong) NSString *heading;
@property (nonatomic, strong) NSNumber *doorStatus;

@end
