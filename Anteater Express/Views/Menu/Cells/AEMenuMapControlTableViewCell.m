//
//  AEMenuMapControlTableViewCell.m
//  Anteater Express
//
//  Created by James Linnell on 12/20/15.
//
//

#import "AEMenuMapControlTableViewCell.h"

@interface AEMenuMapControlTableViewCell ()

@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation AEMenuMapControlTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSelection:(NSInteger)theSelection {
    [self.segmentedControl setSelectedSegmentIndex:theSelection];
}

- (void)setSegmentedControlTarget:(id)target action:(SEL)selector {
    [self.segmentedControl addTarget:target action:selector forControlEvents:UIControlEventValueChanged];
}

@end
