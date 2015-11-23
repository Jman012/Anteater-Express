//
//  AEMenuBannerTableViewCell.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "AEMenuBannerTableViewCell.h"

@interface AEMenuBannerTableViewCell ()

@property (nonatomic, strong) IBOutlet UIImageView *bannerImageView;

@end

@implementation AEMenuBannerTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setBannerImage:(UIImage *)theImage {
    self.bannerImageView.image = theImage;
}

@end
