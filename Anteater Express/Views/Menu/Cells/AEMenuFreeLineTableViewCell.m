//
//  AEMenuFreeLineTableViewCell.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "AEMenuFreeLineTableViewCell.h"

@interface AEMenuFreeLineTableViewCell ()

@property (nonatomic, strong) IBOutlet UIImageView *checkmarkImageView;
@property (nonatomic, strong) IBOutlet UILabel *lineNameLabel;

@end

@implementation AEMenuFreeLineTableViewCell

- (void)awakeFromNib {
    // Initialization code
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
}

@end
