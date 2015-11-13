//
//  AnnouncementCustomCell.m
//  Anteater Express
//
//  Created by Andrew Beier on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnnouncementCustomCell.h"

@implementation AnnouncementCustomCell


@synthesize unreadImage;
@synthesize titleText;
@synthesize detailsText;
@synthesize dateText;
@synthesize routeNameText;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
       // Configure the view for the selected state
}



@end
