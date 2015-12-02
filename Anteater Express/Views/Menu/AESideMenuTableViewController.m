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
#import "LoadingInfo.h"

#import "AEMenuBannerTableViewCell.h"
#import "AEMenuFreeLineTableViewCell.h"
#import "AEMenuPaidLineTableViewCell.h"
#import "AEMenuItemTableViewCell.h"
#import "AEMenuLoadingTableViewCell.h"

#import "AEGetRoutesOp.h"

#import "MapViewController.h"

NSString *kCellIdBannerCell = @"AEMenuBannerCell";
NSString *kCellIdFreeLineCell = @"AEMenuFreeLineCell";
NSString *kCellIdPaidLineCell = @"AEMenuPaidLineCell";
NSString *kCellIdItemCell = @"AEMenuItemCell";
NSString *kCellIdLoadingCell = @"AEMenuLoadingCell";

const NSUInteger kSectionBanner = 0;
const NSUInteger kSectionLines = 1;
const NSUInteger kSectionLinks = 2;

@interface AESideMenuTableViewController ()

@property (nonatomic, strong) NSMutableArray *menuSections;
@property (nonatomic, strong) RoutesAndAnnounceDAO *routesAndAnnounceDAO;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation AESideMenuTableViewController

- (void)initialize {
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.name = @"AESideMenu OpQueue";

    [self constructMenu];
}

- (instancetype)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self initialize];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.revealViewController.rearViewRevealOverdraw = 0.0f;

    [self constructMenu];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)constructLineInfos {
    if (self.routesAndAnnounceDAO == nil) {
        return nil;
    }
    
    NSMutableArray *lineInfos = [[NSMutableArray alloc] init];
    for (NSDictionary *routeDict in [self.routesAndAnnounceDAO getRoutes]) {
        [lineInfos addObject:[[LineInfo alloc] initWithText:routeDict[@"Name"] paid:NO routeId:routeDict[@"Id"] cellIdentifer:kCellIdFreeLineCell]];
    }
    return lineInfos;
}

- (void)constructMenu {
    NSArray *lineInfos = [self constructLineInfos];
    if (lineInfos == nil) {
        lineInfos = @[
                      [[LoadingInfo alloc] initWithCellIdentifer:kCellIdLoadingCell]
                      ];
    }
    
    self.menuSections = [NSMutableArray arrayWithArray:@[
                          @[
                              [[BannerItemInfo alloc] initWithBannerImageName:[UIImage imageNamed:@"AE Banner"] cellIdentifer:kCellIdBannerCell]
                              ],
                          lineInfos,
                          @[
                              [[ItemInfo alloc] initWithText:@"All Route Updates" storyboardIdentifier:@"AllRouteUpdates" cellIdentifer:kCellIdItemCell],
                              [[ItemInfo alloc] initWithText:@"News and About" storyboardIdentifier:@"NewsAndAbout" cellIdentifer:kCellIdItemCell]
                              ]
                          ]];
    
    [self refreshAvailableLines];
}

- (void)refreshAvailableLines {
    // Check if the loading cell is already there or not
    // If so, don't change anything just yet
    // If not, replace all current lines with a loading indicator
    MenuInfo *loadingInfo;
    if (self.menuSections[kSectionLines] == nil || [self.menuSections[kSectionLines] count] == 0) {
        loadingInfo = nil;
    } else {
        loadingInfo = self.menuSections[kSectionLines][0];
    }
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:kSectionLines];

    if (loadingInfo == nil || [loadingInfo.cellIdentifier isEqualToString:kCellIdLoadingCell] == false) {
        [self.tableView beginUpdates];
        
        self.menuSections[kSectionLines] = @[
                                             [[LoadingInfo alloc] initWithCellIdentifer:kCellIdLoadingCell]
                                             ];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
    
    // Now that we know the section has the single loading indicator cell,
    // download the data with an operation object
    AEGetRoutesOp *getRoutesOp = [[AEGetRoutesOp alloc] init];
    getRoutesOp.returnBlock = ^(RoutesAndAnnounceDAO *routesAndAnnounceDAO) {
        [self.tableView beginUpdates];
        
        self.routesAndAnnounceDAO = routesAndAnnounceDAO;
        NSArray *lineInfos = [self constructLineInfos];
        self.menuSections[kSectionLines] = lineInfos;
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        // If the refresh control was pulled to trigger this, turn it off
        [self.refreshControl endRefreshing];
        
        // Then tell the map view that we got this new information, and if it needs
        // to download anything else for it's underlying data structures
        UIViewController *vc = self.revealViewController.frontViewController;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UIViewController *newVc = [[(UINavigationController *)vc viewControllers] firstObject];
            if ([newVc isKindOfClass:[MapViewController class]]) {
                [(MapViewController *)newVc setAllRoutesArray:[routesAndAnnounceDAO getRoutes]];
            }
        }
    };
    
    [self.operationQueue addOperation:getRoutesOp];
    
    
}

#pragma mark - UIRefreshControl

- (void)pullToRefresh {
    [self constructMenu];
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
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdLoadingCell]) {
        AEMenuLoadingTableViewCell *loadingCell = (AEMenuLoadingTableViewCell *)cell;
        loadingCell.userInteractionEnabled = NO;
        [loadingCell.activityIndicatorView startAnimating];
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
        UINavigationController *navVC = (UINavigationController *)self.revealViewController.frontViewController;
        MapViewController *mapVC = (MapViewController *)[[navVC viewControllers] firstObject];
        if (lineInfo.selected) {
            [mapVC removeRoute:lineInfo.routeId];
        } else {
            [mapVC showNewRoute:lineInfo.routeId];
        }
        lineInfo.selected = !lineInfo.selected;
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
