//
//  AnnouncementCustomCell.h
//  Anteater Express
//
//  Created by Andrew Beier on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnnouncementCustomCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *unreadImage;
@property (nonatomic, strong) IBOutlet UILabel *titleText;
@property (nonatomic, strong) IBOutlet UILabel *detailsText;
@property (nonatomic, strong) IBOutlet UILabel *dateText;
@property (nonatomic, strong) IBOutlet UILabel *routeNameText;

@end
