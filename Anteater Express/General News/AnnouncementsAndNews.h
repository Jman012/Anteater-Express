//
//  AnnouncementsAndNews.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentCustomViewController.h"

@interface AnnouncementsAndNews : ParentCustomViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet NSArray *announcementsData;
@property (strong, nonatomic) IBOutlet UITableView *announcementsList;
@property (nonatomic, retain) IBOutlet UITextView* noUpdatesMessage;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * progressView;

- (void)startProgressIndicator:(id)sender;
@end
