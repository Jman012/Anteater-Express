//
//  AEMenuFreeLineTableViewCell.h
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import <UIKit/UIKit.h>

@interface AEMenuFreeLineTableViewCell : UITableViewCell

@property (nonatomic, assign) BOOL checked;
@property (nonatomic, strong) UIColor *color;

- (void)setLineName:(NSString *)name;
- (void)setLineSubtitle:(NSString *)subtitle;
- (void)toggleChecked;
- (void)setActiveLine:(BOOL)activeLine;

@end
