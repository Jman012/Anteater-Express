//
//  Route.m
//  Anteater Express
//
//  Created by James Linnell on 9/26/16.
//
//

#import "Route.h"

@implementation Route

- (NSString *)description {
    return [NSString stringWithFormat:@"id=%@, color=%@, name=%@, shortName=%@, fare=%d, desc=%@", self.id, self.color, self.name, self.shortName, self.fare, self.desc];
}

@end
