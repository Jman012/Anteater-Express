//
//  ArrivalPredictionView.m
//  Anteater Express
//
//  Created by James Linnell on 1/15/16.
//
//

#import "ArrivalPredictionView.h"

@implementation ArrivalPredictionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
    [super layoutSubviews];
}

- (CGSize)intrinsicContentSize {
    CGSize size = self.textLabel.intrinsicContentSize;
    size.width = size.width + self.colorView.frame.size.width + 8;
    return size;
}

@end
