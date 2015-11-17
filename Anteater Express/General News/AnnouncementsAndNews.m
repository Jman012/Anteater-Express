//
//  AnnouncementsAndNews.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnnouncementsAndNews.h"
#import "AnnouncementCustomCell.h"
#import "AnnouncementDetailsViewController.h"
#import "Utilities.h"
#import "MessagesDAL.h"

@interface AnnouncementsAndNews ()

@end

@implementation AnnouncementsAndNews
@synthesize announcementsData; //NSArray
@synthesize announcementsList; //UITableView
@synthesize noUpdatesMessage;
@synthesize progressView; // progress Indicator between pages.

MessagesDAL* messagesDAL;


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
    self.screenName = @"Message List : General News";
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    
    //Setup Messages DAL for the data displayed on this view
    messagesDAL = [[MessagesDAL alloc] initWithArray:announcementsData basedOnType:YES forOneRoute:NO];
    
    self.announcementsList.dataSource = self;
    
    //To make sure the table view auto sizes
    self.announcementsList.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.announcementsList.rowHeight = 62;
    
    self.announcementsList.delegate = self;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    [cell.imageView setImage:[UIImage imageNamed:@"UIUnreadIndicatorPressed.png"]];
    //NSLog(@"%@", [NSString stringWithFormat:@"Cell %ld in Section %ld is selected", (long)indexPath.row, (long)indexPath.section ]);
    
}

- (void)startProgressIndicator:(id)sender{
    if (![progressView isAnimating]) {
        [progressView startAnimating];
    }
}
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    [NSThread detachNewThreadSelector:@selector(startProgressIndicator:) toTarget:self withObject:nil];
    
    if([[segue identifier]
        isEqualToString:@"ShowAnnouncementsDetails"]){ //Code for transition to announcements/news
        
        AnnouncementCustomCell *tempCell = (AnnouncementCustomCell*)[self.announcementsList cellForRowAtIndexPath: [self.announcementsList indexPathForSelectedRow]];
        
        tempCell.unreadImage.hidden = YES;
        
        //Code for transition to selecting a route        
        AnnouncementDetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.newsTitle = tempCell.titleText.text;
        
        detailsViewController.newsData = [announcementsData objectAtIndex: [self.announcementsList indexPathForSelectedRow].row];
        
        //Mark message as read in the NSUserDefault Memory
        [messagesDAL markAsRead: [[[announcementsData objectAtIndex: [self.announcementsList indexPathForSelectedRow].row] valueForKey:@"GlobalAlertId"] stringValue]];
    }
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [progressView stopAnimating];
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
    
    if(!announcementsData || !announcementsData.count) //If it is empty hide list and let show empty message
    {
        self.announcementsList.hidden = YES;
        self.noUpdatesMessage.hidden = NO;
    }
    else //If it isnt empty then just hide error message
    {
        self.announcementsList.hidden = NO;
        self.noUpdatesMessage.hidden = YES;
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
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;
    if([tableView isEqual:self.announcementsList]){
        switch (section) {
            case 0:
            {
                result = [announcementsData count];
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
    
    static NSString *CellIndentifier = @"announcementCell";
    
    AnnouncementCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier];
    
    if(cell == nil) {
        cell = [[AnnouncementCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIndentifier];
    }
    
    NSMutableDictionary* tempAnnouncement = [announcementsData objectAtIndex: indexPath.row];
    
    //Formats the Arrow on the Right Side of each cell
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if([messagesDAL isRead:[[tempAnnouncement valueForKey:@"GlobalAlertId"] stringValue]])
    {
        cell.unreadImage.hidden = YES;
    }
    
    cell.titleText.text = [tempAnnouncement valueForKey:@"GlobalAlertTitle"];
    cell.detailsText.text=[tempAnnouncement valueForKey:@"GlobalAlertMessage"];
    cell.dateText.text=[Utilities dateDisplayString:[tempAnnouncement valueForKey:@"GlobalAlertTimeStamp"]];
    cell.unreadImage.image = [UIImage imageNamed:@"UIUnreadIndicator.png"];
    cell.unreadImage.highlightedImage = [UIImage imageNamed:@"UIUnreadIndicatorPressed.png"];
    
    return cell;
}

@end
