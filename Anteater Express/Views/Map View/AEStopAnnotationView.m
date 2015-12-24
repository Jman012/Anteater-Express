//
//  AEStopAnnotationView.m
//  Anteater Express
//
//  Created by James Linnell on 12/22/15.
//
//

#import "AEStopAnnotationView.h"

//#define RADIUS 10
//#define STROKE_WIDTH 1

#import "ColorCircleView.h"

@interface AEStopAnnotationView ()

@property (nonatomic, strong) ColorCircleView *colorCircleView;

@end

@implementation AEStopAnnotationView

//- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
//    
//    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
//        self.backgroundColor = [UIColor clearColor];
//        self.frame = CGRectMake(0, 0, RADIUS * 2 + STROKE_WIDTH * 2, RADIUS * 2 + STROKE_WIDTH * 2);
//    }
//    return self;
//}
//
//- (void)setColors:(NSArray *)colors {
//    _colors = colors;
//    [self setNeedsDisplay]; // Forces a redraw when new colors arrive.
//}

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


//// Only override drawRect: if you perform custom drawing.
//// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    
////    CGContextClearRect(ctx, rect);
//    
//    // Stroke options
//    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
//    CGContextSetLineWidth(ctx, STROKE_WIDTH);
//    
//    // Handling the multiple pie slices
//    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
//    CGFloat pieSize = 360.0 / (CGFloat)self.colors.count;
//    CGFloat angle = 0.0;
//    
//    if (self.colors.count == 1) {
//        // Special case for single color
//        UIColor *color = [self.colors firstObject];
//        CGRect circleRect = CGRectMake(0, 0, RADIUS * 2 + STROKE_WIDTH * 2, RADIUS * 2 + STROKE_WIDTH * 2);
//        circleRect = CGRectInset(circleRect, STROKE_WIDTH * 2, STROKE_WIDTH * 2);
//        CGContextSetFillColorWithColor(ctx, color.CGColor);
//        CGContextFillEllipseInRect(ctx, circleRect);
//        CGContextStrokeEllipseInRect(ctx, circleRect);
//    } else {
//        // Multiple colors
//        for (UIColor *color in self.colors) {
//            
//            CGPathRef arc = [self CGPathCreateArcWithCenter:center radius:RADIUS startAngle:angle endAngle:angle + pieSize];
//            angle += pieSize;
//            
//            CGContextAddPath(ctx, arc);
//            CGContextSetFillColorWithColor(ctx, color.CGColor);
//            CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
//            CGContextDrawPath(ctx, kCGPathFillStroke);
//        }
//    }
//}
//
//- (CGPathRef)CGPathCreateArcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
//    // Helper function for making arcs
//    
//    CGMutablePathRef path = CGPathCreateMutable();
//    CGPathMoveToPoint(path, nil, center.x, center.y);
//    
//    CGPathAddArc(path,
//                 nil,
//                 center.x, center.y,
//                 radius,
//                 DegreesToRadians(startAngle),
//                 DegreesToRadians(endAngle),
//                 false);
//    CGPathCloseSubpath(path);
//    
//    return path;
//}
//
//CGFloat DegreesToRadians(CGFloat degrees)
//{
//    return degrees * M_PI / 180;
//}
//
//CGFloat RadiansToDegrees(CGFloat radians)
//{
//    return radians * 180 / M_PI;
//}


@end
