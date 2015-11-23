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

- (instancetype)initWithText:(NSString *)theText paid:(BOOL)thePaid cellIdentifer:(NSString *)theCellId;

@end
