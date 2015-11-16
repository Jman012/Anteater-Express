//
//  RouteUpdateDetailsViewController.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParentCustomViewController.h"

@interface RouteUpdateDetailsViewController : ParentCustomViewController

@property (nonatomic, retain) IBOutlet UITextView* updateMessage;
@property (nonatomic, retain) IBOutlet UILabel* updateScreenTitle;
@property (nonatomic, retain) IBOutlet UILabel* updatePostedTime;
@property (nonatomic, retain) IBOutlet UILabel* updateRouteName;
@property (strong, nonatomic) IBOutlet NSMutableDictionary *updateData;

@end
