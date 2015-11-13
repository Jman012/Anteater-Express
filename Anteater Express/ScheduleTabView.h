//
//  ScheduleTabView.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentCustomViewController.h"

@interface ScheduleTabView : ParentCustomViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet NSMutableDictionary *routeData;
@property (nonatomic, retain) IBOutlet NSArray *stopsData;
@property (strong, nonatomic) IBOutlet UITableView *stopsList;
@property (nonatomic, retain) IBOutlet UITextView* noStopsMessage;

@end
