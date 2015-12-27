//
//  AEStopAnnotationView.m
//  Anteater Express
//
//  Created by James Linnell on 12/22/15.
//
//

#import "AEStopAnnotationView.h"

#import "ColorCircleView.h"

@interface AEStopAnnotationView ()

@property (nonatomic, strong) ColorCircleView *colorCircleView;

@end

@implementation AEStopAnnotationView

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        self.colorCircleView = [[ColorCircleView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [self addSubview:self.colorCircleView];
    }
    return self;
}

- (void)setColors:(NSArray *)colors {
    self.colorCircleView.colors = colors;
}

@end
