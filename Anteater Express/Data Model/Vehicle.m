//
//  Vehicle.m
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import "Vehicle.h"

@implementation Vehicle

- (NSString *)description {
    return [NSString stringWithFormat:@"Vehicle id=%@, name=%@", self.id, self.name];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[Vehicle class]]) {
        Vehicle *other = (Vehicle *)object;
        return [self.id isEqualToNumber:other.id] && [self.name isEqualToString:other.name] && [self.latitude isEqualToNumber:other.latitude] && [self.longitude isEqualToNumber:other.longitude] && [self.updated isEqualToString:other.updated] && [self.updatedAgo isEqualToString:other.updatedAgo] && [self.doorStatus isEqualToNumber:other.doorStatus];
    } else {
        return false;
    }
}

- (NSUInteger)hash {
    return self.id.hash + self.name.hash + self.latitude.hash + self.longitude.hash + self.updated.hash + self.updatedAgo.hash + self.doorStatus.hash;
}

@end
