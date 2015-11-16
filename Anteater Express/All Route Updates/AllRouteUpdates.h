//
//  AllRouteUpdates.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentCustomViewController.h"

@interface AllRouteUpdates : ParentCustomViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet NSArray *updatesData;
@property (strong, nonatomic) IBOutlet UITableView *updatesList;
@property (nonatomic, retain) IBOutlet UITextView* noUpdatesMessage;

@end
