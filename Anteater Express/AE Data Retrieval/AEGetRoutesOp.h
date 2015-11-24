//
//  AEGetRoutesOp.h
//  Anteater Express
//
//  Created by James Linnell on 11/24/15.
//
//

#import <Foundation/Foundation.h>

#import "RoutesAndAnnounceDAO.h"

@interface AEGetRoutesOp : NSOperation

@property (nonatomic, strong) void (^returnBlock)(RoutesAndAnnounceDAO *routesAndAnnounceDAO);

@end
