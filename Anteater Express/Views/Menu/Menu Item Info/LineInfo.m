//
//  FreeLineInfo.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "LineInfo.h"

@implementation LineInfo

- (instancetype)initWithText:(NSString *)theText paid:(BOOL)thePaid routeId:(NSNumber *)theRouteId cellIdentifer:(NSString *)theCellId {
    if (self = [super initWithCellIdentifer:theCellId]) {
        self.text = theText;
        self.paid = thePaid;
        self.routeId = theRouteId;
        self.selected = NO;
    }
    return self;
}

@end
