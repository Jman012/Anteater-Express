//
//  AEMenuFreeLineTableViewCell.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "AEMenuFreeLineTableViewCell.h"

#import "CircleCheckmark.h"

static UIImage *checkedImage = nil;
static UIImage *uncheckedImage = nil;

@interface AEMenuFreeLineTableViewCell ()

@property (nonatomic, strong) IBOutlet CircleCheckmark *circleCheckmark;
@property (nonatomic, strong) IBOutlet UILabel *lineNameLabel;

@end

@implementation AEMenuFreeLineTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.checked = false;
    self.circleCheckmark.checkMarkStyle = CircleCheckmarkStyleOpenCircle;
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
        [self.circleCheckmark setChecked:YES];
    } else {
        [self.circleCheckmark setChecked:NO];
    }
}

- (void)setColor:(UIColor *)color {
    _color = color;
    self.circleCheckmark.color = color;
}

- (void)toggleChecked {
    self.checked = !self.checked; // This will call the setter above
}

@end
