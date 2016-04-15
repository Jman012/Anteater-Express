//
//  FreeLineInfo.h
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "MenuInfo.h"

@interface LineInfo : MenuInfo

@property (nonatomic, assign) BOOL paid;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSNumber *routeId;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) NSUInteger numActive;

- (instancetype)initWithText:(NSString *)theText paid:(BOOL)thePaid routeId:(NSNumber *)theRouteId color:(UIColor *)color cellIdentifer:(NSString *)theCellId;

@end
