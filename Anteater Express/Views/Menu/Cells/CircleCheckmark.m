//
//  CircleCheckmark.m
//  Anteater Express
//
//  Created by James Linnell on 12/29/15.
//
//

/* Credit due to http://stackoverflow.com/a/19332828/464870 */

#import "CircleCheckmark.h"

@implementation CircleCheckmark

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self.checked)
        [self drawRectChecked:rect];
    else
    {
        if (self.checkMarkStyle == CircleCheckmarkStyleOpenCircle)
            [self drawRectOpenCircle:rect];
        else if (self.checkMarkStyle == CircleCheckmarkStyleGrayedOut)
            [self drawRectGrayedOut:rect];
    }
}

- (void)setChecked:(bool)checked
{
    _checked = checked;
    [self setNeedsDisplay];
}

- (void)setCheckMarkStyle:(CircleCheckmarkStyle)checkMarkStyle
{
    _checkMarkStyle = checkMarkStyle;
    [self setNeedsDisplay];
}

- (void)drawRectChecked:(CGRect)rect
{
    // General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Shadow Declarations
    UIColor *shadow2 = [UIColor blackColor];
    CGSize shadow2Offset = CGSizeMake(0.1, -0.1);
    CGFloat shadow2BlurRadius = 2.5;
    
    // Frames
    CGRect frame = self.bounds;
    
    // Subframes
    CGRect group = CGRectMake(CGRectGetMinX(frame) + 3, CGRectGetMinY(frame) + 3, CGRectGetWidth(frame) - 6, CGRectGetHeight(frame) - 6);
    
    
    // Group
    {
        // CheckedOval Drawing
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadow2Offset, shadow2BlurRadius, shadow2.CGColor);
        
        // Fill
        [self.color setFill];
        CGContextFillEllipseInRect(context, group);
        
        CGContextRestoreGState(context);
        
        // Stroke
        [[UIColor whiteColor] setStroke];
        CGContextSetLineWidth(context, 1);
        CGContextStrokeEllipseInRect(context, group);
        
        
        
        // Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(group) + 0.27083 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.54167 * CGRectGetHeight(group))];
        [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group) + 0.41667 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.68750 * CGRectGetHeight(group))];
        [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group) + 0.75000 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.35417 * CGRectGetHeight(group))];
        bezierPath.lineCapStyle = kCGLineCapSquare;
        
        [[UIColor whiteColor] setStroke];
        bezierPath.lineWidth = 1.3;
        [bezierPath stroke];
    }
}

- (void)drawRectGrayedOut:(CGRect)rect
{
    // General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Color Declarations
    UIColor *grayTranslucent = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.6];
    
    // Shadow Declarations
    UIColor *shadow2 = [UIColor blackColor];
    CGSize shadow2Offset = CGSizeMake(0.1, -0.1);
    CGFloat shadow2BlurRadius = 2.5;
    
    // Frames
    CGRect frame = self.bounds;
    
    // Subframes
    CGRect group = CGRectMake(CGRectGetMinX(frame) + 3, CGRectGetMinY(frame) + 3, CGRectGetWidth(frame) - 6, CGRectGetHeight(frame) - 6);
    
    // Group
    {
        // UncheckedOval Drawing
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadow2Offset, shadow2BlurRadius, shadow2.CGColor);
        
        // Fill
        [grayTranslucent setFill];
        CGContextFillEllipseInRect(context, group);
        
        CGContextRestoreGState(context);
        
        // Stroke
        [[UIColor whiteColor] setStroke];
        CGContextSetLineWidth(context, 1);
        CGContextStrokeEllipseInRect(context, group);
        
        // Bezier Drawing
        UIBezierPath *bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(group) + 0.27083 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.54167 * CGRectGetHeight(group))];
        [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group) + 0.41667 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.68750 * CGRectGetHeight(group))];
        [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group) + 0.75000 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.35417 * CGRectGetHeight(group))];
        bezierPath.lineCapStyle = kCGLineCapSquare;
        
        [[UIColor whiteColor] setStroke];
        bezierPath.lineWidth = 1.3;
        [bezierPath stroke];
    }
}

- (void)drawRectOpenCircle:(CGRect)rect
{
    // General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    // Shadow Declarations
    UIColor *shadow = [UIColor darkGrayColor];
    CGSize shadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat shadowBlurRadius = 1;
    
    // Frames
    CGRect frame = self.bounds;
    
    // Subframes
    CGRect group = CGRectMake(CGRectGetMinX(frame) + 3, CGRectGetMinY(frame) + 3, CGRectGetWidth(frame) - 6, CGRectGetHeight(frame) - 6);
    
    // Group
    {
        // EmptyOval Drawing
        CGContextSaveGState(context);
        
        // Shadow
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);

        // Circle
        CGContextSetLineWidth(context, 1);
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextStrokeEllipseInRect(context, group);
        
        CGContextRestoreGState(context);
    }
}

@end
