//
//  UpdateTabView.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentCustomViewController.h"

@interface UpdateTabView : ParentCustomViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet NSMutableDictionary *routeData;
@property (weak, nonatomic) IBOutlet NSMutableDictionary *routeUpdatesData;
@property (weak, nonatomic) IBOutlet NSArray *updatesDataArray;
@property (strong, nonatomic) IBOutlet UITableView *announcementsList;
@property (nonatomic, retain) IBOutlet UITextView* noUpdatesMessage;

@end
