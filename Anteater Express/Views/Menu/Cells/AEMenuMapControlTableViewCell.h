//
//  AEMenuMapControlTableViewCell.h
//  Anteater Express
//
//  Created by James Linnell on 12/20/15.
//
//

#import <UIKit/UIKit.h>

@interface AEMenuMapControlTableViewCell : UITableViewCell

- (void)setSelection:(NSInteger)theSelection;
- (void)setSegmentedControlTarget:(id)target action:(SEL)selector;

@end
