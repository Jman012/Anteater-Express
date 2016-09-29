//
//  Stop.h
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import <Foundation/Foundation.h>

@interface Stop : NSObject

@property (nonatomic, assign) NSNumber *id;
@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSString *name;

@end
