//
//  ItemInfo.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "ItemInfo.h"

@implementation ItemInfo

- (instancetype)initWithText:(NSString *)theText storyboardIdentifier:(NSString *)theStoryboardId cellIdentifer:(NSString *)theCellId {
    if (self = [super initWithCellIdentifer:theCellId]) {
        self.text = theText;
        self.storyboardId = theStoryboardId;
    }
    return self;
}

@end
