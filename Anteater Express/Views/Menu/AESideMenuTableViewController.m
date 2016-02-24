//
//  AESideMenuTableViewController.m
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import "AESideMenuTableViewController.h"

#import <SWRevealViewController/SWRevealViewController.h>
#import <MapKit/MapKit.h>

#import "RoutesAndAnnounceDAO.h"
#import "ColorConverter.h"

#import "MenuInfo.h"
#import "BannerItemInfo.h"
#import "LineInfo.h"
#import "ItemInfo.h"
#import "LoadingInfo.h"
#import "MapControlInfo.h"

#import "AEMenuBannerTableViewCell.h"
#import "AEMenuFreeLineTableViewCell.h"
#import "AEMenuPaidLineTableViewCell.h"
#import "AEMenuItemTableViewCell.h"
#import "AEMenuLoadingTableViewCell.h"
#import "AEMenuMapControlTableViewCell.h"

#import "AEGetRoutesOp.h"

#import "MapViewController.h"
#import "RouteDetailViewController.h"

NSString *kCellIdBannerCell =     @"AEMenuBannerCell";
NSString *kCellIdFreeLineCell =   @"AEMenuFreeLineCell";
NSString *kCellIdPaidLineCell =   @"AEMenuPaidLineCell";
NSString *kCellIdItemCell =       @"AEMenuItemCell";
NSString *kCellIdLoadingCell =    @"AEMenuLoadingCell";
NSString *kCellIdMapControlCell = @"AEMenuMapControlCell";

const NSUInteger kSectionBanner =     0;
const NSUInteger kSectionMapControl = 1;
const NSUInteger kSectionLines =      2;
const NSUInteger kSectionLinks =      3;

@interface AESideMenuTableViewController ()

@property (nonatomic, strong) NSMutableArray<NSArray *> *menuSections;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *selectedRouteIds;
@property (nonatomic, strong) RoutesAndAnnounceDAO *routesAndAnnounceDAO;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSTimer *syncSelectedLinesTimer;

@end

@implementation AESideMenuTableViewController


#pragma mark - Init

- (void)initialize {
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.name = @"AESideMenu OpQueue";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"SelectedRouteIds"] != nil) {
        self.selectedRouteIds = [NSMutableSet setWithArray:[userDefaults objectForKey:@"SelectedRouteIds"]];
    } else {
        self.selectedRouteIds = [NSMutableSet set];
    }

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

#pragma mark - View control

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.view.backgroundColor = [UIColor colorWithHue:236.0/360.0 saturation:0.69 brightness:0.40 alpha:1.0];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.revealViewController.rearViewRevealOverdraw = 0.0f;

    [self constructMenu];
    
    // Selected routes might be laoded from userDefaults by now, and
    // the mapView should be loaded by now, so notify it
    UINavigationController *navVC = (UINavigationController *)self.revealViewController.frontViewController;
    MapViewController *mapVC = (MapViewController *)[[navVC viewControllers] firstObject];
    if (mapVC) {
        [self.selectedRouteIds enumerateObjectsUsingBlock:^(NSNumber *routeId, BOOL *stop) {
            [mapVC showNewRoute:routeId];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self syncSelectedLines:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Methods

- (NSArray *)constructLineInfos {
    if (self.routesAndAnnounceDAO == nil) {
        return nil;
    }
    
    NSMutableArray *lineInfos = [[NSMutableArray alloc] init];
    [self.routesAndAnnounceDAO.getRoutes enumerateObjectsUsingBlock:^(NSDictionary *routeDict, NSUInteger idx, BOOL *stop) {
        NSString *titleString = [NSString stringWithFormat:@"%@ - %@", routeDict[@"Abbreviation"], routeDict[@"Name"]];
        LineInfo *newLineInfo = [[LineInfo alloc] initWithText:titleString paid:NO routeId:routeDict[@"Id"] color:[ColorConverter colorWithHexString:routeDict[@"ColorHex"]] cellIdentifer:kCellIdFreeLineCell];
        newLineInfo.selected = [self.selectedRouteIds containsObject:routeDict[@"Id"]];
        [lineInfos addObject:newLineInfo];
        
    }];
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
                          @[
                              [[MapControlInfo alloc] initWithSelection:0 cellIdentifier:kCellIdMapControlCell]
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

#pragma mark - NSTimer

- (void)syncSelectedLines:(NSTimer *)timer {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *selectedRouteIdsArray = [NSArray arrayWithArray:[self.selectedRouteIds allObjects]];
    [userDefaults setObject:selectedRouteIdsArray forKey:@"SelectedRouteIds"];
    [userDefaults synchronize];
    
    self.syncSelectedLinesTimer = nil;
}

#pragma mark - UIRefreshControl

- (void)pullToRefresh {
    [self constructMenu];
}

#pragma mark - UISegmentedControl Target Action

- (void)mapControlValueChanged:(UISegmentedControl *)control {
    MapControlInfo *mapControlInfo = [self.menuSections[kSectionMapControl] firstObject];
    mapControlInfo.selection = control.selectedSegmentIndex;
    
    UINavigationController *navVC = (UINavigationController *)self.revealViewController.frontViewController;
    MapViewController *mapVC = (MapViewController *)[[navVC viewControllers] firstObject];
    switch (mapControlInfo.selection) {
        case 0: {
            [mapVC setMapType:MKMapTypeStandard];
            break;
        }
        
        case 1: {
            [mapVC setMapType:MKMapTypeHybrid];
            break;
        }
        default:
            break;
    }
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
        BannerItemInfo *bannerInfo = (BannerItemInfo *)menuInfo;
        AEMenuBannerTableViewCell *bannerCell = (AEMenuBannerTableViewCell *)cell;
        bannerCell.userInteractionEnabled = NO;
        [bannerCell setBannerImage:bannerInfo.bannerImage];
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdFreeLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        AEMenuFreeLineTableViewCell *freeLineCell = (AEMenuFreeLineTableViewCell *)cell;
        freeLineCell.userInteractionEnabled = YES;
        [freeLineCell setLineName:lineInfo.text];
        [freeLineCell setChecked:lineInfo.selected];
        freeLineCell.color = lineInfo.color;
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdPaidLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        AEMenuPaidLineTableViewCell *paidLineCell = (AEMenuPaidLineTableViewCell *)cell;
        paidLineCell.userInteractionEnabled = YES;
        [paidLineCell setLineName:lineInfo.text];
        [paidLineCell setChecked:lineInfo.selected];
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdItemCell]) {
        ItemInfo *itemInfo = (ItemInfo *)menuInfo;
        AEMenuItemTableViewCell *itemCell = (AEMenuItemTableViewCell *)cell;
        itemCell.userInteractionEnabled = YES;
        itemCell.textLabel.text = itemInfo.text;
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdLoadingCell]) {
        AEMenuLoadingTableViewCell *loadingCell = (AEMenuLoadingTableViewCell *)cell;
        loadingCell.userInteractionEnabled = NO;
        [loadingCell.activityIndicatorView startAnimating];
        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdMapControlCell]) {
        MapControlInfo *mapControlInfo = (MapControlInfo *)menuInfo;
        AEMenuMapControlTableViewCell *mapControlCell = (AEMenuMapControlTableViewCell *)cell;
        [mapControlCell setSelection:mapControlInfo.selection];
        mapControlCell.userInteractionEnabled = YES;
        mapControlCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [mapControlCell setSegmentedControlTarget:self action:@selector(mapControlValueChanged:)];
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
        
        // Get view controller info
        UINavigationController *navVC = (UINavigationController *)self.revealViewController.frontViewController;
        MapViewController *mapVC = (MapViewController *)[[navVC viewControllers] firstObject];
        
        // Tell mapVC
        if (lineInfo.selected) {
            [mapVC removeRoute:lineInfo.routeId];
        } else {
            [mapVC showNewRoute:lineInfo.routeId];
        }
        
        // Update Data Structures
        lineInfo.selected = !lineInfo.selected;
        if ([self.selectedRouteIds containsObject:lineInfo.routeId]) {
            [self.selectedRouteIds removeObject:lineInfo.routeId];
        } else {
            [self.selectedRouteIds addObject:lineInfo.routeId];
        }
        
        if (self.syncSelectedLinesTimer != nil) {
            [self.syncSelectedLinesTimer invalidate];
        }
        self.syncSelectedLinesTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(syncSelectedLines:) userInfo:nil repeats:NO];
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdPaidLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        
        NSLog(@"Toggling %@", lineInfo.text);
        
        // Get view controller info
        UINavigationController *navVC = (UINavigationController *)self.revealViewController.frontViewController;
        MapViewController *mapVC = (MapViewController *)[[navVC viewControllers] firstObject];
        
        // Tell mapVC
        if (lineInfo.selected) {
            [mapVC removeRoute:lineInfo.routeId];
        } else {
            [mapVC showNewRoute:lineInfo.routeId];
        }
        
        // Update Data Structure
        lineInfo.selected = !lineInfo.selected;
        if ([self.selectedRouteIds containsObject:lineInfo.routeId]) {
            [self.selectedRouteIds removeObject:lineInfo.routeId];
        } else {
            [self.selectedRouteIds addObject:lineInfo.routeId];
        }
        
        if (self.syncSelectedLinesTimer != nil) {
            [self.syncSelectedLinesTimer invalidate];
        }
        self.syncSelectedLinesTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(syncSelectedLines:) userInfo:nil repeats:NO];
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.section == kSectionLines) {
        UINavigationController *frontNavController = (UINavigationController *)self.revealViewController.frontViewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
        RouteDetailViewController *destVC = (RouteDetailViewController *)[storyboard instantiateViewControllerWithIdentifier:@"RouteDetailView"];
        [destVC setRoute:self.routesAndAnnounceDAO.getRoutes[indexPath.row]];
        
        [self.revealViewController revealToggleAnimated:YES];
        [frontNavController pushViewController:destVC animated:YES];
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
