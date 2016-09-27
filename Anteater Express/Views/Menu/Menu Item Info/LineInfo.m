//
//  FreeLineInfo.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "LineInfo.h"

@implementation LineInfo

- (instancetype)initWithText:(NSString *)theText paid:(BOOL)thePaid routeId:(NSNumber *)theRouteId color:(UIColor *)color cellIdentifer:(NSString *)theCellId route:(Route *)route {
    if (self = [super initWithCellIdentifer:theCellId]) {
        self.text = theText;
        self.paid = thePaid;
        self.routeId = theRouteId;
        self.selected = NO;
        self.color = color;
        self.numActive = 0;
        self.route = route;
    }
    return self;
}

@end
