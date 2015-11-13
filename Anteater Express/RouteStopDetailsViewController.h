//
//  RouteStopDetailsViewController.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParentCustomViewController.h"

@interface RouteStopDetailsViewController : ParentCustomViewController <UITableViewDelegate, UITableViewDataSource,UIPickerViewDataSource, UIPickerViewDelegate>
{
    __weak IBOutlet UIButton *selectScheduleButton;
    //__weak IBOutlet UIPickerView *selectRoutePicker;
}

@property (strong, nonatomic) IBOutlet NSMutableDictionary *specificStopData;
@property (nonatomic, retain) IBOutlet NSArray *stopData;
@property (strong, nonatomic) IBOutlet UITableView *departureTimesList;
@property (nonatomic, strong) IBOutlet UIPickerView *selectSchedulePicker;
@property (nonatomic, retain) IBOutlet UITextView* noDepartureTimesMessage;
@property (nonatomic, retain) IBOutlet UITextView* generalStopDescription;
@property int stopSetID;
@property NSString *routeName;


- (IBAction)selectScheduleButtonPress:(id)sender;
- (void)pickerTap: (UIGestureRecognizer*) gestureRecognizer;

@end