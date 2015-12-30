//
//  CircleCheckmark.h
//  Anteater Express
//
//  Created by James Linnell on 12/29/15.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CircleCheckmarkStyle)
{
    CircleCheckmarkStyleOpenCircle,
    CircleCheckmarkStyleGrayedOut
};

@interface CircleCheckmark : UIView

@property (nonatomic, assign) bool checked;
@property (nonatomic, assign) CircleCheckmarkStyle checkMarkStyle;
@property (nonatomic, strong) UIColor *color;


@end
