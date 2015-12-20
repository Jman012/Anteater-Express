//
//  MapControlInfo.h
//  Anteater Express
//
//  Created by James Linnell on 12/20/15.
//
//

#import <Foundation/Foundation.h>

#import "MenuInfo.h"

@interface MapControlInfo : MenuInfo

@property (nonatomic, assign) NSInteger selection;

- (instancetype)initWithSelection:(NSInteger)theSelection cellIdentifier:(NSString *)theCellIdentifier;

@end
