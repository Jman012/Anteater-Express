//
//  RouteStopDetailsViewController.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/14/12.
//  Copyright (c) 2012 Anteater Express. All rights reserved.
//

#import "RouteStopDetailsViewController.h"
#import "StopDepartureTimeCell.h"
#import "StopArrivalPredictionDAO.h"
#import "RouteDefinitionDAO.h"
#import "Utilities.h"

@interface RouteStopDetailsViewController ()

@end

@implementation RouteStopDetailsViewController
@synthesize specificStopData;
@synthesize stopData;
@synthesize departureTimesList;
@synthesize selectSchedulePicker;
@synthesize noDepartureTimesMessage;
@synthesize generalStopDescription;
@synthesize stopSetID;
@synthesize routeName;

NSInteger selectedScheduleIndex;
BOOL isToday;
BOOL isNextDepartureTimeFound;
int  nextDepartureTimeRow;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    NSString* viewName = @"Route Schedule : ";
    viewName = [viewName stringByAppendingString:routeName];
    viewName = [viewName stringByAppendingString:@" : "];
    viewName = [viewName stringByAppendingString:[specificStopData objectForKey:@"StopName"]];
    self.screenName = viewName;
    
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    self.departureTimesList.dataSource = self;
    
    self.selectSchedulePicker.dataSource = self;
    
    //To make sure the table view auto sizes
    self.departureTimesList.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.departureTimesList.rowHeight = 22;
    
    self.departureTimesList.delegate = self;
    
    self.selectSchedulePicker.delegate = self;
    
    //[selectScheduleButton setBackgroundColor: [UIColor grayColor]];
    
    [self.selectSchedulePicker setHidden:YES];
    
    selectSchedulePicker.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickerTap:)];
    [selectSchedulePicker addGestureRecognizer:tapGesture];
    
    //Perform reset and possible selection
    [self performResetAndPossibleSelectionOnSchedule];
}

- (void)performResetAndPossibleSelectionOnSchedule
{
    //Check is the selected Schedule Is Active Today
    [self resetScheduleSelection];
    //Calculate selected time/row for schedule
    if(isToday)
    {
        [self calculateSelectedRowForSchedule];
        //Only proceed if it found a matching row
//        if(isNextDepartureTimeFound)
//        {
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow: nextDepartureTimeRow inSection: 0];
//            [departureTimesList selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
//        }
    }
}

- (void)calculateSelectedRowForSchedule
{
    for(int i = 0; i < [[[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"StopDetails"] valueForKey:@"ScheduledTimes"] count]; i++)
    {
        NSMutableDictionary* tempStop = [[[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"StopDetails"] valueForKey:@"ScheduledTimes"] objectAtIndex: i];
        
        NSString* timeFromServer = [tempStop valueForKey:@"DepartureTime"];
        NSArray* timeArray = [timeFromServer componentsSeparatedByString:@":"];
        
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setHour:[[timeArray objectAtIndex:0] intValue]];
        [comps setMinute:[[timeArray objectAtIndex:1] intValue]];
        
        if(isToday && !isNextDepartureTimeFound && [self isTimeGreaterThanNow:comps])
        {
            isNextDepartureTimeFound = YES;
            nextDepartureTimeRow = i;
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    // Release any retained subviews of the main view.
    
    [self.selectSchedulePicker setHidden:YES];
    
    selectedScheduleIndex = 0;
    
    //Sets the NavBar title to the Stop Name
    NSString* stopName          = [specificStopData objectForKey:@"StopName"];
    self.navigationItem.title   = stopName;
    
    //Sets the selected schedule to the first one in the list
    NSString* defaultScheduleName = [[stopData objectAtIndex:0] valueForKey:@"ScheduleName"];
    [selectScheduleButton setTitle:defaultScheduleName forState:UIControlStateNormal];
    
    NSString* generalStopDescriptionString = [specificStopData valueForKey:@"StopLocationGenereal"];
    [generalStopDescription setText: generalStopDescriptionString];
    
}

-(void) resetScheduleSelection
{
    isNextDepartureTimeFound = false;
    isToday = [self isScheduleActiveToday];
}

- (BOOL) isScheduleActiveToday
{
    int today = [Utilities getCurrentDayOfWeek];
    int selectedScheduleIndex = [selectSchedulePicker selectedRowInComponent:0];
    switch(today)
    {
        case 1:
            return [[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"ServiceMon"] intValue] !=0; // if Zero it's NO, otherwise yes
        case 2:
            return [[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"ServiceTue"] intValue] !=0; // if Zero it's NO, otherwise yes
        case 3:
            return [[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"ServiceWed"] intValue] !=0; // if Zero it's NO, otherwise yes
        case 4:
            return [[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"ServiceThu"] intValue] !=0; // if Zero it's NO, otherwise yes
        case 5:
            return [[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"ServiceFri"] intValue] !=0; // if Zero it's NO, otherwise yes
        case 6:
            return [[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"ServiceSat"] intValue] !=0; // if Zero it's NO, otherwise yes
        case 0:
            return [[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"ServiceSun"] intValue] !=0; // if Zero it's NO, otherwise yes
    }
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)selectScheduleButtonPress:(id)sender
{
    //Gives selected color as user clicks button before segue happens
    //Note: Segue is handled via storyboard, not at this spot in the code
    //[sender setBackgroundColor:[UIColor blueColor]];
    //[sender setTitleColor:[UIColor whiteColor] forState: UIControlStateNormal];
    if([selectSchedulePicker numberOfRowsInComponent:0] > 1)
    {
        [self.selectSchedulePicker setHidden:NO];
    }
    else
    {
        selectScheduleButton.adjustsImageWhenHighlighted = NO;
        //selectScheduleButton
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    NSInteger result = 0;
    if([tableView isEqual:self.departureTimesList]){
        result = 1;
    }
    return result;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* result = @"";
    if([tableView isEqual:self.departureTimesList]){
        switch (section) {
            case 0:
            {
                //result = @"Scheduled Departure Times";
                result = @"";
                break;
            }
            case 1:
            {
                result = @"Select Schedule";
                break;
            }
        }
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger result = 0;
    if([tableView isEqual:self.departureTimesList]){
        switch (section) {
            case 0:
            {
                result = [[[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"StopDetails"] valueForKey:@"ScheduledTimes"] count];
                
                //Show or Hide Display Message Indicating No Departure Times
                if(result == 0)
                {
                    [noDepartureTimesMessage setHidden:NO];
                    [departureTimesList setHidden:YES];
                }
                else
                {
                    [noDepartureTimesMessage setHidden:YES];
                    [departureTimesList setHidden:NO];
                }
                break;
            }
            case 1:
            {
                result = 1;
                break;
            }
        }
    }
    return result;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIndentifier = @"departureTimeCell";
    
    StopDepartureTimeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    
    if(cell == nil) {
        cell = [[StopDepartureTimeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIndentifier];
    }
    
    if(indexPath.section == 0) //First section to show route departure times
    {
        NSMutableDictionary* tempStop = [[[[stopData objectAtIndex:selectedScheduleIndex] valueForKey:@"StopDetails"] valueForKey:@"ScheduledTimes"] objectAtIndex: indexPath.row];
        
        NSString* timeFromServer = [tempStop valueForKey:@"DepartureTime"];
        NSArray* timeArray = [timeFromServer componentsSeparatedByString:@":"];
        
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setHour:[[timeArray objectAtIndex:0] intValue]];
        [comps setMinute:[[timeArray objectAtIndex:1] intValue]];
        
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        NSDate *dateTime = [calendar dateFromComponents:comps];
        NSString *time = [NSDateFormatter localizedStringFromDate:dateTime dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
        
        NSString *cellText = @"";
        if(indexPath.row == nextDepartureTimeRow && isNextDepartureTimeFound)
        {
            cellText = [time stringByAppendingString:@" (Next Departure)"];
            [cell setUserInteractionEnabled:YES];
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        else
        {
            //Never allow cell to be clicked
            [cell setUserInteractionEnabled:NO];
            cellText = time;
        }
        cell.stopDepartureTimeText.text = cellText;
    }
    else //Second section to show select route schedule
    {
        cell.stopDepartureTimeText.text = @"";
    }
    
    return cell;
}

- (BOOL) isTimeGreaterThanNow: (NSDateComponents *) dateComponent
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate: [NSDate date]];
    NSInteger curHour = [components hour];
    NSInteger curMinute = [components minute];
    
    return ([dateComponent hour] == curHour && [dateComponent minute] > curMinute) || ([dateComponent hour] > curHour);
}

//- (void)selectRow:(NSUInteger)rowNum inTableView:(UITableView *)tableView
//{
//    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:rowNum inSection:0];
//
//    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
//}

//UI PICKER METHODS
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    NSInteger result = 0;
    if([pickerView isEqual:self.selectSchedulePicker])
    {
        result = 1;
    }
    return result;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    NSInteger result = 0;
    if ([pickerView isEqual:self.selectSchedulePicker])
    {
        result = [stopData count];
    }
    return result;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *result = nil;
    if ([pickerView isEqual:self.selectSchedulePicker])
    {
        NSMutableDictionary* tempSchedule = [stopData objectAtIndex: row];
        
        NSString* scheduleName = [tempSchedule valueForKey:@"ScheduleName"];
        
        result = [NSString stringWithFormat:@"%@", scheduleName];
    }
    return result;
}

- (void)pickerTap: (UIGestureRecognizer*) gestureRecognizer
{
    
    //Find out where the user tapped
    CGFloat myPositionY = [gestureRecognizer locationInView: selectSchedulePicker].y;
    
    //Height of picker row (divided into 5 equal parts)
    CGFloat rowHeight = selectSchedulePicker.frame.size.height/5;
    
    //Variable to hold the selected row
    NSInteger selectedRowIndex = [selectSchedulePicker selectedRowInComponent:0];
    
    
    //Check if any action is needed.
    // We consider anything above the currently selected item as one above the selected item.
    // Similarly, anything below the currently selected item is one below the selected item.
    
    if(myPositionY < 2*rowHeight) // above center
    {
        selectedRowIndex -= ([selectSchedulePicker selectedRowInComponent:0] > 0? 1 : 0);
    }
    else if(myPositionY < 3*rowHeight ) // center
    {
        selectedRowIndex = [selectSchedulePicker selectedRowInComponent:0]; // originally selected component.
        
        //they double clicked?
        NSMutableDictionary* tempRoute = [stopData objectAtIndex: selectedRowIndex];
        
        NSString* scheduleTitle;
        
        if(tempRoute != nil) //Set button to selectedSchedule if it was found
        {
            scheduleTitle = [tempRoute valueForKey:@"ScheduleName"];
        }
        else { //There was no valid route  selected
            scheduleTitle = @"Select a Schedule";
        }
        
        [selectScheduleButton setTitle:scheduleTitle forState:UIControlStateNormal];
        
        selectedScheduleIndex = [selectSchedulePicker selectedRowInComponent:0];
        
        [self.selectSchedulePicker setHidden:YES];
        
        //Perform reset and possible selection
        [self performResetAndPossibleSelectionOnSchedule];
        
        [departureTimesList reloadData];
    }
    else // below center
    {
        selectedRowIndex += ([selectSchedulePicker selectedRowInComponent:0] < [selectSchedulePicker numberOfRowsInComponent:0]-1? 1 : 0);
    }
    
    [selectSchedulePicker selectRow:selectedRowIndex inComponent:0 animated:YES];
    
}


@end
