//
//  ViewController.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentCustomViewController.h"

@interface ViewController : ParentCustomViewController <UIPickerViewDataSource, UIPickerViewDelegate, UIAlertViewDelegate>
{
    __weak IBOutlet UIButton *selectRouteButton;
    //__weak IBOutlet UIPickerView *selectRoutePicker;
}

@property (weak, nonatomic) IBOutlet NSArray *allRoutes;
@property (nonatomic, strong) IBOutlet UIPickerView *selectRoutePicker;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityView;

- (IBAction)selectRouteButtonPress:(id)sender;

- (IBAction)goToRouteSelectedButtonPress:(id)sender;

- (void)startProgressIndicator:(id)sender;

- (void)pickerTap: (UIGestureRecognizer*) gestureRecognizer;

@end
