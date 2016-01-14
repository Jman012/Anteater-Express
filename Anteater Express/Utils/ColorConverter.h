//
//  ColorConverter.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorConverter : NSObject

- (UIColor *) colorWithHexString: (NSString *) stringToConvert;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;

@end
