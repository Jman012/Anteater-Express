//
//  ItemInfo.h
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "MenuInfo.h"

@interface ItemInfo : MenuInfo

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *storyboardId;

- (instancetype)initWithText:(NSString *)theText storyboardIdentifier:(NSString *)theStoryboardId cellIdentifer:(NSString *)theCellId;

@end
