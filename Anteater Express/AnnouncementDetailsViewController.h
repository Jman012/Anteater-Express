//
//  AnnouncementDetailsViewController.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentCustomViewController.h"

@interface AnnouncementDetailsViewController : ParentCustomViewController

@property (nonatomic, copy) NSString* newsTitle;
@property (nonatomic, retain) IBOutlet UITextView* newsMessage;
@property (nonatomic, retain) IBOutlet UILabel* newsScreenTitle;
@property (nonatomic, retain) IBOutlet UILabel* newsPostedTime;
@property (strong, nonatomic) IBOutlet NSMutableDictionary *newsData;

@end
