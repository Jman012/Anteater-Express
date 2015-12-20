//
//  AEMenuFreeLineTableViewCell.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "AEMenuFreeLineTableViewCell.h"

static UIImage *checkedImage = nil;
static UIImage *uncheckedImage = nil;

@interface AEMenuFreeLineTableViewCell ()

@property (nonatomic, strong) IBOutlet UIImageView *checkmarkImageView;
@property (nonatomic, strong) IBOutlet UILabel *lineNameLabel;

@end

@implementation AEMenuFreeLineTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.checked = false;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected statex
}

- (void)setLineName:(NSString *)name {
    self.lineNameLabel.text = name;
}

- (void)setChecked:(BOOL)checked {
    // TODO: Implement this with a picture.
    if (checked) {
        self.checkmarkImageView.image = [AEMenuFreeLineTableViewCell checkedImage];
    } else {
        self.checkmarkImageView.image = [AEMenuFreeLineTableViewCell uncheckedImage];
    }
}

- (void)toggleChecked {
    self.checked = !self.checked; // This will call the setter above
}

+ (UIImage *)checkedImage {
    if (checkedImage == nil) {
        checkedImage = [UIImage imageNamed:@"checked_checkbox"];
    }
    return checkedImage;
}

+ (UIImage *)uncheckedImage {
    if (uncheckedImage == nil) {
        uncheckedImage = [UIImage imageNamed:@"unchecked_checkbox"];
    }
    return uncheckedImage;
}

@end
