//
//  MenuItemInfo.h
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import <Foundation/Foundation.h>

@interface MenuInfo : NSObject

@property (nonatomic, strong) NSString *cellIdentifier;

- (instancetype)initWithCellIdentifer:(NSString *)theCellId;

@end
