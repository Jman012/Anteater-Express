//
//  AllRouteUpdates.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AllRouteUpdates.h"
#import "AnnouncementCustomCell.h"
#import "RouteUpdateDetailsViewController.h"
#import "Utilities.h"
#import "MessagesDAL.h"

@interface AllRouteUpdates ()

@end

@implementation AllRouteUpdates
@synthesize updatesData; //NSArray
@synthesize updatesList; //UITableView
@synthesize noUpdatesMessage;

MessagesDAL* messagesDAL_allRouteUpdates;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.screenName = @"Message List : Route : All";
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    
    //Setup Messages DAL for the data displayed on this view
    messagesDAL_allRouteUpdates = [[MessagesDAL alloc] initWithArray:updatesData basedOnType:NO forOneRoute:NO];
    
    self.updatesList.dataSource = self;
    
    //To make sure the table view auto sizes
    self.updatesList.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.updatesList.rowHeight = 62;
    
    self.updatesList.delegate = self;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //NSLog(@"%@", [NSString stringWithFormat:@"Cell %ld in Section %ld is selected", (long)indexPath.row, (long)indexPath.section ]);
    
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([[segue identifier]
        isEqualToString:@"AllRouteUpdatesDetails"]){ //Code for transition to announcements/news
        
        //Code for transition to selecting a route        
        RouteUpdateDetailsViewController *detailsViewController = [segue destinationViewController];
        
        detailsViewController.updateData = [updatesData objectAtIndex: [self.updatesList indexPathForSelectedRow].row];
        
        //Mark message as read in the NSUserDefault Memory
        NSString* routeID       = [[[updatesData objectAtIndex: [self.updatesList indexPathForSelectedRow].row] valueForKey:@"RouteId"] stringValue];
        NSString* routeAlertID  = [[[updatesData objectAtIndex: [self.updatesList indexPathForSelectedRow].row] valueForKey:@"RouteAlertId"] stringValue];
        NSString* objectStringIdentifier  = [routeID stringByAppendingString:@"_"];
        objectStringIdentifier  = [objectStringIdentifier stringByAppendingString:routeAlertID];
        [messagesDAL_allRouteUpdates markAsRead: objectStringIdentifier];
        
        AnnouncementCustomCell *tempCell = (AnnouncementCustomCell*)[self.updatesList cellForRowAtIndexPath: [self.updatesList indexPathForSelectedRow]];
        tempCell.unreadImage.hidden = YES;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:true];
    // Do anything on reloading and appearing of this view.
    
    if(!updatesData || !updatesData.count) //If it is empty hide list and let show empty message
    {
        self.updatesList.hidden = YES;
        self.noUpdatesMessage.hidden = NO;
    }
    else //If it isnt empty then just hide error message
    {
        self.updatesList.hidden = NO;
        self.noUpdatesMessage.hidden = YES;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger result = 0;
    if([tableView isEqual:self.updatesList]){
        result = 1;
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;
    if([tableView isEqual:self.updatesList]){
        switch (section) {
            case 0:
            {
                result = [updatesData count];
                break;
            }
        }
    }
    return result;
}
- (NSString*) dateFormatter:(NSString*) dateFromJSON
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, yyyy hh:mm:ss a"];
    NSDate *date = [formatter dateFromString:dateFromJSON];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setDoesRelativeDateFormatting:YES];
    NSString *finalDateString = [formatter stringFromDate:date];
    
    return  finalDateString;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIndentifier = @"routeUpdateCell";
    
    AnnouncementCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    
    if(cell == nil) {
        cell = [[AnnouncementCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIndentifier];
    }
    
    NSMutableDictionary* tempAnnouncement = [updatesData objectAtIndex: indexPath.row];
    
    //Formats the Arrow on the Right Side of each cell
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    
    NSString* routeID       = [[tempAnnouncement valueForKey:@"RouteId"] stringValue];
    NSString* routeAlertID  = [[tempAnnouncement valueForKey:@"RouteAlertId"] stringValue];
    NSString* objectString  = [routeID stringByAppendingString:@"_"];
    objectString  = [objectString stringByAppendingString:routeAlertID];
    if([messagesDAL_allRouteUpdates isRead: objectString])
    {
        cell.unreadImage.hidden = YES;
    }
    
    cell.titleText.text = [tempAnnouncement valueForKey:@"RouteAlertTitle"];
    cell.detailsText.text=[tempAnnouncement valueForKey:@"RouteAlertMessage"];
    cell.dateText.text=[Utilities dateDisplayString:[tempAnnouncement valueForKey:@"RouteAlertTimeStamp"]];
    cell.routeNameText.text=[tempAnnouncement valueForKey:@"RouteName"];
    cell.unreadImage.image = [UIImage imageNamed:@"UIUnreadIndicator.png"];
    cell.unreadImage.highlightedImage = [UIImage imageNamed:@"UIUnreadIndicatorPressed.png"]; 
    
    
    return cell;
}

@end
