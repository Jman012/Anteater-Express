//
//  AESideMenuTableViewController.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "AESideMenuTableViewController.h"

#import <SWRevealViewController/SWRevealViewController.h>

#import "RoutesAndAnnounceDAO.h"

#import "MenuInfo.h"
#import "BannerItemInfo.h"
#import "LineInfo.h"
#import "ItemInfo.h"

#import "AEMenuBannerTableViewCell.h"
#import "AEMenuFreeLineTableViewCell.h"
#import "AEMenuPaidLineTableViewCell.h"
#import "AEMenuItemTableViewCell.h"

NSString *kCellIdBannerCell = @"AEMenuBannerCell";
NSString *kCellIdFreeLineCell = @"AEMenuFreeLineCell";
NSString *kCellIdPaidLineCell = @"AEMenuPaidLineCell";
NSString *kCellIdItemCell = @"AEMenuItemCell";

@interface AESideMenuTableViewController ()

@property(nonatomic, strong) NSArray *menuSections;
@property(nonatomic, strong) RoutesAndAnnounceDAO *routesAndAnnounceDAO;

@end

@implementation AESideMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    [self constructMenu];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)constructMenu {
    // TODO: Background this. It loads stuff over the network!
    self.routesAndAnnounceDAO = [[RoutesAndAnnounceDAO alloc] init];
    NSMutableArray *lineInfos = [[NSMutableArray alloc] init];
    for (NSDictionary *routeDict in [self.routesAndAnnounceDAO getRoutes]) {
        [lineInfos addObject:[[LineInfo alloc] initWithText:routeDict[@"Name"] paid:NO cellIdentifer:kCellIdFreeLineCell]];
    }
    
    self.menuSections = @[
                          @[
                              [[BannerItemInfo alloc] initWithBannerImageName:[UIImage imageNamed:@"AE Banner"] cellIdentifer:kCellIdBannerCell]
                              ],
                          lineInfos,
                          @[
                              [[ItemInfo alloc] initWithText:@"All Route Updates" storyboardIdentifier:@"AllRouteUpdates" cellIdentifer:kCellIdItemCell],
                              [[ItemInfo alloc] initWithText:@"News and About" storyboardIdentifier:@"NewsAndAbout" cellIdentifer:kCellIdItemCell]
                              ]
                          ];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.menuSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section >= [self.menuSections count]) {
        return 0;
    }
    
    NSArray *sectionRows = self.menuSections[section];
    return [sectionRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuInfo *menuInfo = self.menuSections[indexPath.section][indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:menuInfo.cellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuInfo *menuInfo = self.menuSections[indexPath.section][indexPath.row];
    
    if ([menuInfo.cellIdentifier isEqualToString:kCellIdBannerCell]) {
        BannerItemInfo *bannerInfo =(BannerItemInfo *)menuInfo;
        AEMenuBannerTableViewCell *bannerCell = (AEMenuBannerTableViewCell *)cell;
        bannerCell.userInteractionEnabled = NO;
        [bannerCell setBannerImage:bannerInfo.bannerImage];
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdFreeLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        AEMenuFreeLineTableViewCell *freeLineCell = (AEMenuFreeLineTableViewCell *)cell;
        freeLineCell.userInteractionEnabled = YES;
        [freeLineCell setLineName:lineInfo.text];
        [freeLineCell setChecked:NO];
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdPaidLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        AEMenuPaidLineTableViewCell *paidLineCell = (AEMenuPaidLineTableViewCell *)cell;
        paidLineCell.userInteractionEnabled = YES;
        [paidLineCell setLineName:lineInfo.text];
        [paidLineCell setChecked:NO];
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdItemCell]) {
        ItemInfo *itemInfo = (ItemInfo *)menuInfo;
        AEMenuItemTableViewCell *itemCell = (AEMenuItemTableViewCell *)cell;
        itemCell.userInteractionEnabled = YES;
        itemCell.textLabel.text = itemInfo.text;
        
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuInfo *menuInfo = self.menuSections[indexPath.section][indexPath.row];
    if ([menuInfo.cellIdentifier isEqualToString:kCellIdBannerCell]) {
        BannerItemInfo *bannerInfo = (BannerItemInfo *)menuInfo;
        return [bannerInfo preferredCellHeightForWidth:self.revealViewController.rearViewRevealWidth];

    } else {
        return 44.0f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MenuInfo *menuInfo = self.menuSections[indexPath.section][indexPath.row];
    
    if ([menuInfo.cellIdentifier isEqualToString:kCellIdFreeLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        
        NSLog(@"Toggling %@", lineInfo.text);
        [self.revealViewController revealToggleAnimated:YES];

        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdPaidLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        
        NSLog(@"Toggling %@", lineInfo.text);
        [self.revealViewController revealToggleAnimated:YES];

        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdItemCell]) {
        ItemInfo *itemInfo = (ItemInfo *)menuInfo;
        
        UINavigationController *frontNavController = (UINavigationController *)self.revealViewController.frontViewController;
        
        // TODO: Cache these views somehow.
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
        UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:itemInfo.storyboardId];
        
//        [self.revealViewController setFrontViewController:destVC];
        [self.revealViewController revealToggleAnimated:YES];
        
        [frontNavController pushViewController:destVC animated:YES];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
