//
//  AEMenuPaidLineTableViewCell.h
//  
//
//  Created by James Linnell on 11/22/15.
//
//

#import <UIKit/UIKit.h>

@interface AEMenuPaidLineTableViewCell : UITableViewCell

@property (nonatomic, assign) BOOL checked;
@property (nonatomic, strong) UIColor *color;

- (void)setLineName:(NSString *)name;
- (void)toggleChecked;

@end
