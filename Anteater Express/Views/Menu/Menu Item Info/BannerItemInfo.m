//
//  BannerItemInfo.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "BannerItemInfo.h"

@implementation BannerItemInfo

- (instancetype)initWithBannerImageName:(UIImage *)theImage cellIdentifer:(NSString *)theCellId {
    if (self = [super initWithCellIdentifer:theCellId]) {
        self.bannerImage = theImage;
    }
    return self;
}

- (CGFloat)preferredCellHeightForWidth:(CGFloat)width {
    return (width / self.bannerImage.size.width) * self.bannerImage.size.height;
}

@end
