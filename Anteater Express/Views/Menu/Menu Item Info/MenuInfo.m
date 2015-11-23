//
//  MenuItemInfo.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "MenuInfo.h"

@implementation MenuInfo

- (instancetype)initWithCellIdentifer:(NSString *)theCellId {
    if (self = [super init]) {
        self.cellIdentifier = theCellId;
    }
    return self;
}

@end
