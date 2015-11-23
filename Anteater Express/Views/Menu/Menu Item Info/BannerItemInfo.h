//
//  BannerItemInfo.h
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "MenuInfo.h"

@interface BannerItemInfo : MenuInfo

@property (nonatomic, strong) UIImage *bannerImage;

- (instancetype)initWithBannerImageName:(UIImage *)theImage cellIdentifer:(NSString *)theCellId;
- (CGFloat)preferredCellHeightForWidth:(CGFloat)width;

@end
