//
//  AEMenuPaidLineTableViewCell.m
//  
//
//  Created by James Linnell on 11/22/15.
//
//

#import "AEMenuPaidLineTableViewCell.h"

static UIImage *checkedImage = nil;
static UIImage *uncheckedImage = nil;

@interface AEMenuPaidLineTableViewCell ()

@property (nonatomic, strong) IBOutlet UIImageView *checkmarkImageView;
@property (nonatomic, strong) IBOutlet UILabel *lineNameLabel;

@end

@implementation AEMenuPaidLineTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.checked = false;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setLineName:(NSString *)name {
    self.lineNameLabel.text = name;
}

- (void)setChecked:(BOOL)checked {
    // TODO: Implement this with a picture.
    if (checked) {
        self.checkmarkImageView.image = [AEMenuPaidLineTableViewCell checkedImage];
    } else {
        self.checkmarkImageView.image = [AEMenuPaidLineTableViewCell uncheckedImage];
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
