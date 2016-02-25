//
//  RouteDetailViewController.m
//  Anteater Express
//
//  Created by James Linnell on 2/22/16.
//
//

#import "RouteDetailViewController.h"

#import "ColorConverter.h"
#import "RouteSchedulesDAO.h"
#import "RouteDetailHeaderView.h"

@interface RouteDetailViewController ()

@property (nonatomic, strong) IBOutlet UIView *colorView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) IBOutlet UILabel *fareLabel;

@property (nonatomic, strong) IBOutlet UISegmentedControl *dayControl;
@property (nonatomic, strong) IBOutlet UITableView *scheduleTableView;

@property (nonatomic, strong) UIColor *routeColor;
@property (nonatomic, strong) NSString *routeNavBarTitle;
@property (nonatomic, strong) NSString *routeTitle;
@property (nonatomic, strong) NSString *routeDetail;
@property (nonatomic, strong) NSString *routeFareText;

@property (nonatomic, strong) NSMutableArray *routeScheduleDays;
@property (nonatomic, strong) NSMutableDictionary *routeScheduleFormattedData;
@property (nonatomic, assign) BOOL isRouteScheduleLoading;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

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
    self.fareLabel.text = self.routeFareText;
    
    [self.dayControl removeAllSegments];
    for (int i = 0; i < self.routeScheduleDays.count; ++i) {
        [self.dayControl insertSegmentWithTitle:self.routeScheduleDays[i] atIndex:i animated:NO];
    }
    [self.dayControl setSelectedSegmentIndex:0];
    
}

- (void)setRoute:(NSDictionary *)route {
    self.routeNavBarTitle = [NSString stringWithFormat:@"%@ Line", route[@"Abbreviation"]];
    
    self.routeColor = [ColorConverter colorWithHexString:route[@"ColorHex"]];
    self.routeTitle = [NSString stringWithFormat:@"%@ Line - %@", route[@"Abbreviation"], route[@"Name"]];
    self.routeDetail = route[@"Description"];
    NSNumber *fare = route[@"Routefare"];
    self.routeFareText = fare.boolValue ? @"Paid" : @"Free";
    
    self.isRouteScheduleLoading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [self setRouteScheduleTextForRouteName:route[@"Name"]];
    });

}

- (void)setRouteScheduleTextForRouteName:(NSString *)routeName {
    // Intended for background execution

//    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
//    dispatch_sync(dispatch_get_main_queue(), ^() {
//        [self.scheduleTableView addSubview:refreshControl];
//        [refreshControl beginRefreshing];
//        [self.scheduleTableView scrollRectToVisible:CGRectZero animated:YES];
//    });
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDateFormatter *readableDateFormatter = [[NSDateFormatter alloc] init];
    readableDateFormatter.dateFormat = @"h:mm a";
    readableDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    self.routeScheduleDays = [NSMutableArray array];
    self.routeScheduleFormattedData = [NSMutableDictionary dictionary];
    
    RouteSchedulesDAO *routeSchedulesDao = [[RouteSchedulesDAO alloc] initWithRouteName:routeName];
    for (NSDictionary *stopsDict in routeSchedulesDao.getRouteStops) {
        NSNumber *stopId = stopsDict[@"StopId"];
        NSString *extendedStopDescription = stopsDict[@"StopLocationSpecific"];
        NSArray *stopScheduledTimes = [routeSchedulesDao getStopScheduledTimes:stopId.intValue];
        
        
        for (NSDictionary *stopInfoForDay in stopScheduledTimes) {
            NSString *dayName = stopInfoForDay[@"ScheduleName"];
            if ([dayName isEqualToString:@"Monday - Thursday"]) {
                // Unfortunately a simple hack
                // TODO: Make smarter
                dayName = @"Mon - Thu";
            }
            NSString *stopName = stopInfoForDay[@"StopDetails"][@"StopName"];
            NSString *subtitle = stopInfoForDay[@"StopDetails"][@"StopLocationSpecific"];
            
            if ([self.routeScheduleDays containsObject:dayName] == false) {
                [self.routeScheduleDays addObject:dayName];
            }
            
            NSMutableArray *formattedTimes = [NSMutableArray array];
            
            NSDate *startTime;
            NSDate *secondToLast;
            NSDate *endTime;
            NSArray *timesForThisStopAndDay = stopInfoForDay[@"StopDetails"][@"ScheduledTimes"];
            NSMutableArray *differences = [NSMutableArray array];

            // For each specific time for this set of days
            for (int i = 0; i < timesForThisStopAndDay.count; ++i) {
                NSDictionary *time = timesForThisStopAndDay[i];
                NSDate *date = [dateFormatter dateFromString:time[@"DepartureTime"]];
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
                        NSString *startTimeString = [readableDateFormatter stringFromDate:startTime];
                        NSString *secondToLastString = [readableDateFormatter stringFromDate:secondToLast];
                        NSString *endTimeString = [readableDateFormatter stringFromDate:endTime];
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
            
            NSMutableArray *daysArray = self.routeScheduleFormattedData[dayName];
            if (stopName != nil && formattedTimes != nil) {
                [daysArray addObject:@{
                                       @"title": [NSString stringWithFormat:@"%@", stopName],
                                       @"times": formattedTimes,
                                       @"subtitle": subtitle // Unused currently
                                       }];
            }
            
        }
        
    }
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.dayControl.selectedSegmentIndex == -1) {
        return 0;
    }
    
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
    return dayAllStopsInfo.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
    NSArray *stopTimes = dayAllStopsInfo[section][@"times"];
    return stopTimes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"RouteDetailTimeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
    NSArray *stopTimes = dayAllStopsInfo[indexPath.section][@"times"];
    NSString *stopTimeRow = stopTimes[indexPath.row];
    
    cell.textLabel.text = stopTimeRow;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
    return dayAllStopsInfo[section][@"title"];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *daySelected = self.routeScheduleDays[self.dayControl.selectedSegmentIndex];
    NSArray *dayAllStopsInfo = self.routeScheduleFormattedData[daySelected];
    
    RouteDetailHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"RouteDetailHeaderView" owner:tableView options:nil] firstObject];
    headerView.titleLabel.text = dayAllStopsInfo[section][@"title"];
    headerView.subtitleLabel.text = dayAllStopsInfo[section][@"subtitle"];
    
    return [headerView systemLayoutSizeFittingSize:CGSizeMake(tableView.frame.size.width, 30)].height;
}

@end
