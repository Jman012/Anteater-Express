//
//  AEGetRoutesOp.m
//  Anteater Express
//
//  Created by James Linnell on 11/24/15.
//
//

#import "AEGetRoutesOp.h"

@implementation AEGetRoutesOp

- (void)main {
    
    // Instantiating this will perform the network request
    RoutesAndAnnounceDAO *routesAndAnnounceDAO = [[RoutesAndAnnounceDAO alloc] init];
//    sleep(1);
    
    dispatch_sync(dispatch_get_main_queue(), ^() {
        self.returnBlock(routesAndAnnounceDAO);
    });
}

@end
