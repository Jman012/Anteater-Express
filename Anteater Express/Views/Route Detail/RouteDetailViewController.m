//
//  RouteDetailViewController.m
//  Anteater Express
//
//  Created by James Linnell on 2/22/16.
//
//

#import "RouteDetailViewController.h"

#import <FRHyperLabel/FRHyperLabel.h>

#import "ColorConverter.h"
#import "RouteSchedulesDAO.h"
#import "ExactTimeTableViewCell.h"
#import "StopArrivalPredictionDAO.h"

@interface RouteDetailViewController ()

// Header Views
@property (nonatomic, strong) IBOutlet UIView *colorView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) IBOutlet FRHyperLabel *fareLabel;

// Information Views
@property (nonatomic, strong) IBOutlet UISegmentedControl *dayControl;
@property (nonatomic, strong) IBOutlet UITableView *scheduleTableView;
@property (strong, nonatomic) IBOutlet UISwitch *approximateTimeSwitch;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (strong, nonatomic) IBOutlet UIView *topHairline;

// Header Data
@property (nonatomic, strong) UIColor *routeColor;
@property (nonatomic, strong) NSString *routeNavBarTitle;
@property (nonatomic, strong) NSString *routeTitle;
@property (nonatomic, strong) NSString *routeDetail;
@property (nonatomic, strong) NSString *routeFareText;

// Information Data General
@property (nonatomic, strong) NSMutableArray *routeScheduleDays;
@property (nonatomic, assign) BOOL isRouteScheduleLoading;
// Information Data Approximate
@property (nonatomic, strong) NSMutableDictionary *routeScheduleFormattedData;
// Information Data Exact
@property (nonatomic, strong) NSMutableDictionary *exactRouteScheduleData;

@property (nonatomic, strong) NSString *now;
@property (nonatomic, strong) NSDateFormatter *formatterPDT;
@property (nonatomic, strong) NSDateFormatter *formatterGMT;
@property (nonatomic, strong) NSDateFormatter *readableDateFormatter;



/*
 
 Used for ordering, then jumping to the right dict
 [ "Monday - Thursday", "Saturday", "Sunday" ]

 Actual info
 {
    "Monday - Thursday" : {
        [
            {
                "title" : "University Center, South"
                "times" : [
                    "Every ? minutes from ? to ?",
                    "Every ? minutes from ? to ?"
                ]
            },
            {
                "title" : "Other stop title"
                 "times" : [
                     "Every ? minutes from ? to ?",
                     "Every ? minutes from ? to ?"
                 ]
            }
        ]
    },
    "Saturday" : {
 
    },
    "Sunday" : {
 
    }
 }
 
 */

@end

@implementation RouteDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.dayControl addTarget:self action:@selector(dayControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    [self updateHeaderInfo];
    
    if (self.isRouteScheduleLoading) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.scheduleTableView addSubview:self.refreshControl];
        [self.refreshControl beginRefreshing];
        [self.scheduleTableView scrollRectToVisible:CGRectMake(0, -50, self.scheduleTableView.frame.size.width, self.scheduleTableView.frame.size.height) animated:YES];
    }
    
    self.approximateTimeSwitch.on = YES;
//    self.approximateTimeSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75);
    
    self.formatterPDT = [[NSDateFormatter alloc] init];
    self.formatterPDT.dateFormat = @"HH:mm:ss";
    self.formatterPDT.timeZone = [NSTimeZone timeZoneWithName:@"PDT"];
    
    self.formatterGMT = [[NSDateFormatter alloc] init];
    self.formatterGMT.dateFormat = @"HH:mm:ss";
    self.formatterGMT.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    
    self.readableDateFormatter = [[NSDateFormatter alloc] init];
    self.readableDateFormatter.dateFormat = @"h:mm a";
    self.readableDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    self.now = [self.formatterPDT stringFromDate:[NSDate date]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.topHairline.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        if ([constraint.identifier isEqualToString:@"hairline"]) {
            constraint.constant = (1.0 / [UIScreen mainScreen].scale);
        }
    }];
}

- (IBAction)approximateTimeSwitchValuechanged:(UISwitch *)sender {
    self.now = [self.formatterPDT stringFromDate:[NSDate date]];
    
    [self.scheduleTableView reloadData];
}

- (void)dayControlValueChanged:(UISegmentedControl *)sender {
    [self.scheduleTableView reloadData];
    [self.scheduleTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)updateHeaderInfo {
    self.title = self.routeNavBarTitle;
    
    self.colorView.backgroundColor = self.routeColor;
    self.titleLabel.text = self.routeTitle;
    self.detailLabel.text = self.routeDetail;
    
    if ([self.routeFareText isEqualToString:@"Paid"]) {
        //Step 1: Define a normal attributed string for non-link texts
        NSString *string = @"Paid";
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0]};
        
        self.fareLabel.attributedText = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        
        //Step 2: Define a selection handler block
        void(^handler)(FRHyperLabel *label, NSString *substring) = ^(FRHyperLabel *label, NSString *substring){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.shuttle.uci.edu/ride/fares/"]];
        };
        
        //Step 3: Add link substrings
        [self.fareLabel setLinksForSubstrings:@[@"Paid"] withLinkHandler:handler];
    } else {
        self.fareLabel.text = self.routeFareText;
    }
    
    [self.dayControl removeAllSegments];
    for (int i = 0; i < self.routeScheduleDays.count; ++i) {
        [self.dayControl insertSegmentWithTitle:self.routeScheduleDays[i] atIndex:i animated:NO];
    }
    [self.dayControl setSelectedSegmentIndex:0];
    
}

- (BOOL)loadInformationFromCache:(Route *)route {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastSavedStr = [NSString stringWithFormat:@"routeScheduleLastSaved-%@", route.id];
    NSString *routeScheduleDaysStr = [NSString stringWithFormat:@"routeScheduleDays-%@", route.id];
    NSString *routeScheduleFormattedDataStr = [NSString stringWithFormat:@"routeScheduleFormattedData-%@", route.id];
    NSString *exactRouteScheduleDataStr = [NSString stringWithFormat:@"exactRouteScheduleData-%@", route.id];
    
    NSDate *lastSaved = [userDefaults objectForKey:lastSavedStr];
    NSLog(@"Loading schedule for route %@, lastSaved data = %@, interval = %f", route.shortName, lastSaved, [lastSaved timeIntervalSinceNow]);

    // If the time since loaded is more then 2 days
    // min = 60 sec, hour = 60*60 sec, day = 24*60*60
    if (fabs([lastSaved timeIntervalSinceNow]) > 3 * 24 * 60 * 60) {
        // Then say we could not load the stuff, to get new schedule
        return false;
    }
    
    self.routeScheduleDays = [userDefaults objectForKey:routeScheduleDaysStr];
    self.routeScheduleFormattedData = [userDefaults objectForKey:routeScheduleFormattedDataStr];
    self.exactRouteScheduleData = [userDefaults objectForKey:exactRouteScheduleDataStr];
    
    return (self.routeScheduleDays != nil) && (self.routeScheduleFormattedData != nil) && (self.exactRouteScheduleData != nil);
    
}

- (void)setRoute:(Route *)route {
    
    self.routeNavBarTitle = [NSString stringWithFormat:@"%@ Line", route.shortName];
    
    self.routeColor = [ColorConverter colorWithHexString:route.color];
    self.routeTitle = [NSString stringWithFormat:@"%@ Line - %@", route.shortName, route.name];
    self.routeDetail = route.desc;
    if (self.routeDetail == nil) {
        self.routeDetail = @"";
    }
    BOOL fare = route.fare;
    
    self.routeFareText = fare ? @"Paid" : @"Free";
    
    self.isRouteScheduleLoading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        BOOL loadedFromDisk = [self loadInformationFromCache:route];
        if (loadedFromDisk == false) {
            [self setRouteScheduleTextForRouteName:route.scheduleName routeId:route.id];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^() {
                [self updateHeaderInfo];
                
                if (self.refreshControl != nil) {
                    [self.refreshControl endRefreshing];
                    [self.refreshControl removeFromSuperview];
                }
                [self.scheduleTableView reloadData];
                [self.scheduleTableView scrollRectToVisible:CGRectZero animated:YES];
                self.isRouteScheduleLoading = NO;
            });
        }
    });
    
    self.screenName = [NSString stringWithFormat:@"Route Schedule - %@", self.routeNavBarTitle];

}

- (void)setRouteScheduleTextForRouteName:(NSString *)routeName routeId:(NSNumber *)routeId {
    // Intended for background execution
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    NSMutableDictionary *dayPrioritiesToDayNames = [NSMutableDictionary dictionary];
    self.routeScheduleDays = [NSMutableArray array];
    self.routeScheduleFormattedData = [NSMutableDictionary dictionary];
    self.exactRouteScheduleData = [NSMutableDictionary dictionary];
    
    NSMutableArray *stopIds = [NSMutableArray array];
    
    RouteSchedulesDAO *routeSchedulesDao = [[RouteSchedulesDAO alloc] initWithRouteName:routeName];
    for (NSDictionary *stopsDict in routeSchedulesDao.getRouteStops) {
        NSNumber *stopId = stopsDict[@"StopId"];
        [stopIds addObject:stopId];
        NSArray *stopScheduledTimes = [routeSchedulesDao getStopScheduledTimes:stopId.intValue];
        
        for (NSDictionary *stopInfoForDay in stopScheduledTimes) {
            NSString *dayName = stopInfoForDay[@"ScheduleName"];
            if ([dayName isEqualToString:@"Monday - Thursday"]) {
                // Unfortunately a simple hack
                // TODO: Make smarter
                dayName = @"Mon - Thu";
            }
            __block NSNumber *dayPriority = @0;
            NSArray *serviceAllDays = @[@"ServiceSun", @"ServiceMon", @"ServiceTue", @"ServiceWed", @"ServiceThu", @"ServiceFri", @"ServiceSat"];
            [serviceAllDays enumerateObjectsUsingBlock:^(NSString *serviceDay, NSUInteger idx, BOOL *stop) {
                NSNumber *onDay = stopInfoForDay[serviceDay];
                if ([onDay isEqualToNumber:@1]) {
                    dayPriority = [NSNumber numberWithUnsignedInteger:idx];
                    *stop = YES;
                }
            }];
            NSString *stopName = stopInfoForDay[@"StopDetails"][@"StopName"];
            NSString *subtitle = stopInfoForDay[@"StopDetails"][@"StopLocationSpecific"];
            
            dayPrioritiesToDayNames[dayPriority] = dayName;
            
            NSMutableArray *formattedTimes = [NSMutableArray array];
            
            NSDate *startTime;
            NSDate *secondToLast;
            NSDate *endTime;
            NSArray *timesForThisStopAndDay = stopInfoForDay[@"StopDetails"][@"ScheduledTimes"];
            NSMutableArray *differences = [NSMutableArray array];
            
            

            // For each specific time for this set of days
            NSMutableArray *exactTimes = [NSMutableArray array];
            
            for (int i = 0; i < timesForThisStopAndDay.count; ++i) {
                NSDictionary *time = timesForThisStopAndDay[i];
                NSDate *date = [dateFormatter dateFromString:time[@"DepartureTime"]];
                
                // Add to exact times array
//                [exactTimes addObject:[readableDateFormatter stringFromDate:date]];
                [exactTimes addObject:time[@"DepartureTime"]];
                
                if (startTime == nil) {
                    startTime = date;
                }
                secondToLast = endTime;
                endTime = date;
                
                if (secondToLast != nil) {
                    NSTimeInterval diff = [endTime timeIntervalSinceDate:secondToLast];
                    // Convert to minutes, but keeping precision
                    [differences addObject:[NSNumber numberWithDouble:diff / 60.0]];
                }
                
                if (differences.count >= 2) {
                    NSNumber *first = differences[differences.count - 2];
                    NSNumber *next = differences[differences.count - 1];
                    // If there's a big enough jump, OR this is the last time, make a new section
                    BOOL lastTimeOfTheSchedule = i == timesForThisStopAndDay.count - 1;
                    if (next.doubleValue - first.doubleValue > 5 || lastTimeOfTheSchedule) {
                        // Threshold of 5. So if the times from from ~5 minutes apart
                        // to ~10 minutes apart, we can mark it off as a new segment
                        
                        // Calc the average
                        double summation = 0;
                        for (int j = 0; j < differences.count - 1; ++j) {
                            NSNumber *timeDifference = differences[j];
                            summation += timeDifference.doubleValue;
                        }
                        double averageTimeBetweenStops = summation / (differences.count - 1);

                        // Make the string
                        NSString *startTimeString = [self.readableDateFormatter stringFromDate:startTime];
                        NSString *secondToLastString = [self.readableDateFormatter stringFromDate:secondToLast];
                        NSString *endTimeString = [self.readableDateFormatter stringFromDate:endTime];
                        NSString *text = [NSString stringWithFormat:@"Every ~%d minutes from %@ to %@", (int)round(averageTimeBetweenStops), startTimeString, (lastTimeOfTheSchedule ? endTimeString : secondToLastString)];
                        [formattedTimes addObject:text];
                        
                        // Reset the needed variables
                        startTime = secondToLast;
                        secondToLast = endTime;
                        endTime = nil;
                        [differences removeAllObjects];
                    }
                }
                
            }

            // Add to the main data
            if (self.routeScheduleFormattedData[dayName] == nil) {
                self.routeScheduleFormattedData[dayName] = [NSMutableArray array];
            }
            
//            NSLog(@"Getting preds for stopsetid=%@, stopid=%@", self.routeStopSetId, stopId);
//            StopArrivalPredictionDAO *stopArrivalPredictions = [[StopArrivalPredictionDAO alloc] initWithStopSetID:self.routeStopSetId.intValue andStopID:stopId.intValue];
//            NSString *bigString = [self formattedSubtitleForPredictions:[stopArrivalPredictions.getArrivalTimes valueForKey:@"Predictions"]];
//            NSLog(@"Big string: %@", bigString);
//            NSArray *strings = [bigString componentsSeparatedByString:@"\n"];
//            [strings enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
//                [formattedTimes insertObject:str atIndex:idx];
//            }];
            
            NSMutableArray *daysArray = self.routeScheduleFormattedData[dayName];
            if (stopName != nil && formattedTimes != nil) {
                [daysArray addObject:@{
                                       @"title": [NSString stringWithFormat:@"%@", stopName],
                                       @"times": formattedTimes,
                                       @"subtitle": subtitle // Unused currently
                                       }];
            }
            
            
            
            
            
            // Add to exact data
            if (self.exactRouteScheduleData[dayName] == nil) {
                self.exactRouteScheduleData[dayName] = [NSMutableArray array];
            }
            
            NSMutableArray *exactDaysArray = self.exactRouteScheduleData[dayName];
            if (stopName != nil && exactTimes != nil) {
                [exactDaysArray addObject:@{
                                            @"title": [NSString stringWithFormat:@"%@", stopName],
                                            @"times": exactTimes
                                            }];
            }
            
        }
        
    }
    
    [[[dayPrioritiesToDayNames allKeys] sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(NSNumber *dayPriority, NSUInteger idx, BOOL *stop) {
        if ([self.routeScheduleDays containsObject:dayPrioritiesToDayNames[dayPriority]] == false) {
            [self.routeScheduleDays addObject:dayPrioritiesToDayNames[dayPriority]];
        }
    }];
    

    // Save info as a cache
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastSavedStr = [NSString stringWithFormat:@"routeScheduleLastSaved-%@", routeId];
    NSString *routeScheduleDaysStr = [NSString stringWithFormat:@"routeScheduleDays-%@", routeId];
    NSString *routeScheduleFormattedDataStr = [NSString stringWithFormat:@"routeScheduleFormattedData-%@", routeId];
    NSString *exactRouteScheduleDataStr = [NSString stringWithFormat:@"exactRouteScheduleData-%@", routeId];
    
    [userDefaults setObject:[NSDate date]                   forKey:lastSavedStr];
    [userDefaults setObject:self.routeScheduleDays          forKey:routeScheduleDaysStr];
    [userDefaults setObject:self.routeScheduleFormattedData forKey:routeScheduleFormattedDataStr];
    [userDefaults setObject:self.exactRouteScheduleData     forKey:exactRouteScheduleDataStr];
    [userDefaults synchronize];
    NSLog(@"Saved, confirmed save date = %@", [userDefaults objectForKey:lastSavedStr]);
    
    dispatch_sync(dispatch_get_main_queue(), ^() {
        [self updateHeaderInfo];
        
        if (self.refreshControl != nil) {
            [self.refreshControl endRefreshing];
            [self.refreshControl removeFromSuperview];
        }
        [self.scheduleTableView reloadData];
        [self.scheduleTableView scrollRectToVisible:CGRectZero animated:YES];
        self.isRouteScheduleLoading = NO;
    });
}

- (NSString *)formattedSubtitleForPredictions:(NSArray *)predictions {
    __block NSString *subtitle = @"";

    
    [predictions enumerateObjectsUsingBlock:^(NSDictionary *predictionDict, NSUInteger idx, BOOL *stopInner) {
        subtitle = [subtitle stringByAppendingString:@"\n"];
        subtitle = [subtitle stringByAppendingString:@"  Bus "];
        subtitle = [subtitle stringByAppendingString:[predictionDict[@"BusName"] stringValue]];
        subtitle = [subtitle stringByAppendingString:@"\t"];
        
        NSString* minutesTillArrival = [predictionDict[@"Minutes"] stringValue];
        if([minutesTillArrival isEqualToString: @"0"])
        {
            subtitle = [subtitle stringByAppendingString:@"arriving"];
        }
        else
        {
            subtitle = [subtitle stringByAppendingString:@"in "];
            
            subtitle = [subtitle stringByAppendingString:minutesTillArrival];
            subtitle = [subtitle stringByAppendingString:@" min"];
        }
    }];
    
    return subtitle;
}

#pragma mark - Table View Data Source / Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.approximateTimeSwitch.on) {
        return 30.0f;
    } else {
        return 18.0f;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.dayControl.selectedSegmentIndex == -1) {
        return 0;
    }
    
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo;
    if (self.approximateTimeSwitch.on) {
        dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
        return dayAllStopsInfo.count;
    } else {
        dayAllStopsInfo = self.exactRouteScheduleData[daySelected];
        return dayAllStopsInfo.count;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo;
    if (self.approximateTimeSwitch.on) {
        dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
        NSArray *stopTimes = dayAllStopsInfo[section][@"times"];
        return stopTimes.count;
    } else {
        dayAllStopsInfo = self.exactRouteScheduleData[daySelected];
        NSArray *stopTimes = dayAllStopsInfo[section][@"times"];
        return (stopTimes.count / 4) + MIN(stopTimes.count % 4, 1);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"RouteDetailTimeCell";
    static NSString *exactIdentifier = @"ExactRouteDetailTimeCell";
    
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo;
    if (self.approximateTimeSwitch.on) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
        NSArray *stopTimes = dayAllStopsInfo[indexPath.section][@"times"];
        NSString *stopTimeRow = stopTimes[indexPath.row];
        
        cell.textLabel.text = stopTimeRow;
        
        return cell;
    } else {
        ExactTimeTableViewCell *exactCell = (ExactTimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:exactIdentifier];
        dayAllStopsInfo = self.exactRouteScheduleData[daySelected];
        NSArray *stopTimes = dayAllStopsInfo[indexPath.section][@"times"];
        NSArray *labelNames = @[@"label1", @"label2", @"label3", @"label4"];
        
        for (int i = 0; i < 4; ++i) {
            NSUInteger idx = indexPath.row * 4 + i;
            if (idx < stopTimes.count) {
                NSString *str = stopTimes[idx];
                
                NSDate *date = [self.formatterGMT dateFromString:str];
                NSString *readableString = [self.readableDateFormatter stringFromDate:date];
                
                NSString *rowDateNow = stopTimes[idx];
                NSString *rowDatePrev;
                NSAttributedString *attributedString = nil;
                if (idx - 1 < stopTimes.count) {
                    rowDatePrev = stopTimes[idx - 1];
                    
                    NSComparisonResult one = [rowDatePrev compare:self.now];
                    NSComparisonResult two = [rowDateNow compare:self.now];
                    if ((one == NSOrderedSame || one == NSOrderedAscending) && two == NSOrderedDescending) {
                        attributedString = [[NSAttributedString alloc] initWithString:readableString attributes:@{NSForegroundColorAttributeName:[UIColor blackColor],NSBackgroundColorAttributeName:[UIColor colorWithRed:0.999 green:0.986 blue:0.0 alpha:1.0],NSFontAttributeName:[UIFont systemFontOfSize:10.0]}];
                        
                    }
                }

                UILabel *label = [exactCell valueForKey:labelNames[i]];
                if (attributedString) {
                    label.attributedText = attributedString;
                } else {
                    label.text = readableString;
                }
            } else {
                UILabel *label = [exactCell valueForKey:labelNames[i]];
                label.text = @"";
            }
        }
        
        return exactCell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.approximateTimeSwitch.on) {
        NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
        NSArray *dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
        return dayAllStopsInfo[section][@"title"];
    } else {
        NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
        NSArray *dayAllStopsInfo = self.exactRouteScheduleData[daySelected];
        return dayAllStopsInfo[section][@"title"];
    }
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
//    NSArray *dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
//    
//    RouteDetailHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"RouteDetailHeaderView" owner:tableView options:nil] firstObject];
//    headerView.titleLabel.text = dayAllStopsInfo[section][@"title"];
//    headerView.subtitleLabel.text = dayAllStopsInfo[section][@"subtitle"];
//    
//    return headerView;
//}

@end
