//
//  UpdateTabView.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RouteUpdatesDAO.h"

#import "UpdateTabView.h"
#import "AnnouncementCustomCell.h"
#import "RouteUpdateDetailsViewController.h"
#import "Utilities.h"
#import "MessagesDAL.h"

RouteUpdatesDAO* routeUpdatesDAO;

@interface UpdateTabView ()

@end

@implementation UpdateTabView
@synthesize routeUpdatesData; //NSMutableDictionary
@synthesize routeData; //NSMutableDictionary of route info to get name, etc.
@synthesize updatesDataArray; //NSArray
@synthesize announcementsList; //UITableView
@synthesize noUpdatesMessage;

MessagesDAL* messagesDAL;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated  
{
    [super viewWillAppear:true];
    //Reset title bar name after it was changed so backbutton would have a certain text
    /*UINavigationBar* tabNavBar  = [[self navigationController] navigationBar];
    NSString* routeName         = [routeData objectForKey:@"Name"];
    tabNavBar.topItem.title     = routeName;*/
    
//    NSString* routeName = [routeData objectForKey:@"Name"];
//    
//    //Get Route Updates Information
//    routeUpdatesDAO = [[RouteUpdatesDAO alloc] initWithRouteName: routeName];
//    
//    //Load updates into arrays
//    updatesDataArray    = [routeUpdatesDAO getRouteUpdates];
//    
//    self.noUpdatesMessage.text = [[NSString alloc] initWithFormat:@"No Route Updates are Currently Posted for %@", routeName];
//    
//    if(!updatesDataArray || !updatesDataArray.count) //If it is empty hide list and let show empty message
//    {
//        self.announcementsList.hidden = YES;
//        self.noUpdatesMessage.hidden = NO;
//    }
//    else //If it isnt empty then just hide error message
//    {
//        self.announcementsList.hidden = NO;
//        self.noUpdatesMessage.hidden = YES;
//    }
//    
//    //Setup Messages DAL for the data displayed on this view
//    messagesDAL = [[MessagesDAL alloc] initWithArray:updatesDataArray basedOnType:NO forOneRoute:YES];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    self.announcementsList.dataSource = self;
    
    //To make sure the table view auto sizes
    self.announcementsList.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.announcementsList.rowHeight = 62;
    
    self.announcementsList.delegate = self;
    
    NSString* routeName = [routeData objectForKey:@"Name"];
    
    NSString* viewName = @"Message List : Route : ";
    viewName = [viewName stringByAppendingString:routeName];
    self.trackedViewName = viewName;
    
    //Get Route Updates Information
    routeUpdatesDAO = [[RouteUpdatesDAO alloc] initWithRouteName: routeName];
    
    //Load updates into arrays
    updatesDataArray    = [routeUpdatesDAO getRouteUpdates];
    
    self.noUpdatesMessage.text = [[NSString alloc] initWithFormat:@"No Route Updates are Currently Posted for %@", routeName];
    
    if(!updatesDataArray || !updatesDataArray.count) //If it is empty hide list and let show empty message
    {
        self.announcementsList.hidden = YES;
        self.noUpdatesMessage.hidden = NO;
    }
    else //If it isnt empty then just hide error message
    {
        self.announcementsList.hidden = NO;
        self.noUpdatesMessage.hidden = YES;
    }
    
    //Setup Messages DAL for the data displayed on this view
    messagesDAL = [[MessagesDAL alloc] initWithArray:updatesDataArray basedOnType:NO forOneRoute:YES];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    NSLog(@"Selected Index Update: %d", self.tabBarController.selectedIndex);

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //Action when table view selected.  Handed already with storyboard segue
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([[segue identifier]
        isEqualToString:@"ShowUpdatesDetails"]){
        
        //Code for transition to selecting route update       
        RouteUpdateDetailsViewController *detailsViewController = [segue destinationViewController];
        
        detailsViewController.updateData = [updatesDataArray objectAtIndex: [self.announcementsList indexPathForSelectedRow].row];
        
        //Mark message as read in the NSUserDefault Memory
        NSString* routeID       = [[[updatesDataArray objectAtIndex: [self.announcementsList indexPathForSelectedRow].row] valueForKey:@"RouteId"] stringValue];
        NSString* routeAlertID  = [[[updatesDataArray objectAtIndex: [self.announcementsList indexPathForSelectedRow].row] valueForKey:@"RouteAlertId"] stringValue];
        NSString* objectStringIdentifier  = [routeID stringByAppendingString:@"_"];
        objectStringIdentifier  = [objectStringIdentifier stringByAppendingString:routeAlertID];
        [messagesDAL markAsRead: objectStringIdentifier];
        
        //Hide or unhide read blue bubble on GUI
        AnnouncementCustomCell *tempCell = (AnnouncementCustomCell*)[self.announcementsList cellForRowAtIndexPath: [self.announcementsList indexPathForSelectedRow]];
        tempCell.unreadImage.hidden = YES;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger result = 0;
    if([tableView isEqual:self.announcementsList]){
        result = 1;
        //result = [announcementsData count];
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;
    if([tableView isEqual:self.announcementsList]){
        switch (section) {
            case 0:
            {
                result = [updatesDataArray count];
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
    
    NSMutableDictionary* tempAnnouncement = [updatesDataArray objectAtIndex: indexPath.row];
    
    //Formats the Arrow on the Right Side of each cell
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    
    NSString* routeID       = [[tempAnnouncement valueForKey:@"RouteId"] stringValue];
    NSString* routeAlertID  = [[tempAnnouncement valueForKey:@"RouteAlertId"] stringValue];
    NSString* objectString  = [routeID stringByAppendingString:@"_"];
    objectString  = [objectString stringByAppendingString:routeAlertID];
    if([messagesDAL isRead:objectString])
    {
        cell.unreadImage.hidden = YES;
    }
    
    cell.titleText.text = [tempAnnouncement valueForKey:@"RouteAlertTitle"];
    cell.detailsText.text=[tempAnnouncement valueForKey:@"RouteAlertMessage"];
    cell.dateText.text= [Utilities dateDisplayString:[tempAnnouncement valueForKey:@"RouteAlertTimeStamp"]];
    cell.unreadImage.image = [UIImage imageNamed:@"UIUnreadIndicator.png"];
    cell.unreadImage.highlightedImage = [UIImage imageNamed:@"UIUnreadIndicatorPressed.png"]; 
    
    return cell;
    
}

@end
