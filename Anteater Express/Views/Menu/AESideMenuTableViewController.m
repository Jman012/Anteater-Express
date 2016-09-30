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

#import "AEDataModel.h"
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
#import "AEGetVehiclesOp.h"

#import "MapViewController.h"
#import "RouteDetailViewController.h"

NSString *kCellIdBannerCell =     @"AEMenuBannerCell";
NSString *kCellIdFreeLineCell =   @"AEMenuFreeLineCell2";
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
@property (nonatomic, strong) NSArray<Route*> *routeList;
@property (nonatomic, strong) NSDate *lastRoutesAndAnnounceRefreshDate;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSTimer *retryDownloadLinesTimer;

@end

@implementation AESideMenuTableViewController


#pragma mark - Init

- (void)initialize {
    [AEDataModel.shared addDelegate:self];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.name = @"AESideMenu OpQueue";
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
    
//    self.view.backgroundColor = [UIColor colorWithHue:236.0/360.0 saturation:0.69 brightness:0.40 alpha:1.0];
    self.view.backgroundColor = [UIColor colorWithHue:209.0/360.0 saturation:0.10 brightness:0.90 alpha:1.0];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
//    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    
    self.revealViewController.rearViewRevealOverdraw = 0.0f;

    [self constructMenu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
//    [self syncSelectedLines:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applicationDidBecomeActive:(NSNotification *)sender {
    // If the application became active and the menu data is too old,
    // then refresh the data
    
    NSDate *now = [NSDate date];
    NSTimeInterval limit = 1 /*hour*/ * 60 /*min/hr*/ * 60 /*sec/min*/;
    if ([now timeIntervalSinceDate:self.lastRoutesAndAnnounceRefreshDate] >= limit) {
        NSLog(@"Menu data old. Refreshing.");
        
        [self constructMenu];
    }
}

#pragma mark - Methods

- (NSArray *)constructLineInfos {
    if (self.routeList == nil) {
        return nil;
    }
    
    NSMutableArray *lineInfos = [[NSMutableArray alloc] init];
    [self.routeList enumerateObjectsUsingBlock:^(Route *route, NSUInteger idx, BOOL *stop) {
        
        LineInfo *newLineInfo = [[LineInfo alloc] initWithText:[NSString stringWithFormat:@"%@ - %@", route.shortName, route.name]
                                                          paid:route.fare
                                                       routeId:route.id
                                                         color:[ColorConverter colorWithHexString:route.color]
                                                 cellIdentifer:kCellIdFreeLineCell
                                                         route:route];
        
        NSArray<Vehicle*> *vehicles = [AEDataModel.shared vehiclesForRouteId:route.id];
        newLineInfo.numActive = vehicles == nil ? -1 : vehicles.count;
        newLineInfo.selected = [AEDataModel.shared.selectedRoutes containsObject:route.id];
        [lineInfos addObject:newLineInfo];
        
    }];
    return lineInfos;
}

- (void)constructMenu {
    NSArray *lineInfos = [self constructLineInfos];

    self.menuSections = [NSMutableArray arrayWithArray:@[
                          @[
                              [[BannerItemInfo alloc] initWithBannerImageName:[UIImage imageNamed:@"Anteater-Express-Banner"] cellIdentifer:kCellIdBannerCell]
                              ],
                          @[
                              [[MapControlInfo alloc] initWithSelection:0 cellIdentifier:kCellIdMapControlCell]
                              ]
                          ]];
    if (lineInfos) {
        [self.menuSections addObject:lineInfos];
    } else {
        [self.menuSections addObject:@[]];
    }
    [self.menuSections addObject:
                          @[
                              [[ItemInfo alloc] initWithText:@"About" storyboardIdentifier:@"About" cellIdentifer:kCellIdItemCell]
                              ]
                         ];
    
    [self refreshAvailableLines];
}

- (void)refreshAvailableLines {
    
    // Now that we know the section has the single loading indicator cell,
    // download the data with an operation object
    [AEDataModel.shared refreshRoutes];
}

- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshRouteList:(NSArray<Route *> *)routeList {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:kSectionLines];
    
    self.lastRoutesAndAnnounceRefreshDate = [NSDate date];
    
    [self.tableView beginUpdates];
    
    self.routeList = routeList;
    NSArray *lineInfos = [self constructLineInfos];
    self.menuSections[kSectionLines] = lineInfos;
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
    
    // Request the vehicle data ONCE for each line to see if there are any
    // vehicles present, and if so, grey out the circles
    [self.routeList enumerateObjectsUsingBlock:^(Route *route, NSUInteger idx, BOOL *stop) {
        [AEDataModel.shared refreshVehiclesForRoute:route];
    }];
    
    // If the refresh control was pulled to trigger this, turn it off
    [self.refreshControl endRefreshing];
    
}

- (void)aeDataModelDidGetErrorRefreshingRoutes:(AEDataModel *)aeDataModel {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:kSectionLines];

    self.lastRoutesAndAnnounceRefreshDate = [NSDate date];
    
    [self.tableView beginUpdates];
    
    self.routeList = @[];
    self.menuSections[kSectionLines] = @[];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
    
    [self.refreshControl endRefreshing];
}
     
- (void)aeDataModel:(AEDataModel *)aeDataModel didRefreshVehicles:(NSArray<Vehicle *> *)vehicleList forRoute:(Route *)route {
    [self.menuSections[kSectionLines] enumerateObjectsUsingBlock:^(LineInfo *lineInfo, NSUInteger idx, BOOL *stop) {
        if ([lineInfo.routeId isEqualToNumber:route.id]) {
            lineInfo.numActive = vehicleList.count;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:kSectionLines]] withRowAnimation:UITableViewRowAnimationNone];
            *stop = YES;
        }
    }];
}

- (void)aeDataModel:(AEDataModel *)aeDataModel didSelectRoute:(NSNumber *)routeId {
    [self.menuSections[kSectionLines] enumerateObjectsUsingBlock:^(LineInfo *lineInfo, NSUInteger idx, BOOL *stop) {
        if ([lineInfo.routeId isEqualToNumber:routeId]) {
            lineInfo.selected = true;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:kSectionLines]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

- (void)aeDataModel:(AEDataModel *)aeDataModel didDeselectRoute:(NSNumber *)routeId {
    [self.menuSections[kSectionLines] enumerateObjectsUsingBlock:^(LineInfo *lineInfo, NSUInteger idx, BOOL *stop) {
        if ([lineInfo.routeId isEqualToNumber:routeId]) {
            lineInfo.selected = false;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:kSectionLines]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
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
        [freeLineCell setLineName:[NSString stringWithFormat:@"%@%@", (lineInfo.paid ? @"($) " : @""), lineInfo.text]];
        if (lineInfo.numActive == 1) {
            [freeLineCell setLineSubtitle:@"1 bus"];
        } else if (lineInfo.numActive < 0) {
            [freeLineCell setLineSubtitle:@"Loading..."];
        } else {
            [freeLineCell setLineSubtitle:[NSString stringWithFormat:@"%lu buses", (unsigned long)lineInfo.numActive]];
        }
        [freeLineCell setChecked:lineInfo.selected];
        [freeLineCell setActiveLine:lineInfo.numActive != 0];
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
        
        // Update Data Structures
        if (lineInfo.selected) {
            [AEDataModel.shared deselectRoute:lineInfo.route];
        } else {
            [AEDataModel.shared selectRoute:lineInfo.route];
        }

        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdPaidLineCell]) {
        LineInfo *lineInfo = (LineInfo *)menuInfo;
        
        NSLog(@"Toggling %@", lineInfo.text);
        
        // Update Data Structure
        if (lineInfo.selected) {
            [AEDataModel.shared deselectRoute:lineInfo.route];
        } else {
            [AEDataModel.shared selectRoute:lineInfo.route];
        }

        
    } else if ([menuInfo.cellIdentifier isEqualToString:kCellIdItemCell]) {
        ItemInfo *itemInfo = (ItemInfo *)menuInfo;
        
        UINavigationController *frontNavController = (UINavigationController *)self.revealViewController.frontViewController;
        
        // TODO: Cache these views somehow.
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
        UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:itemInfo.storyboardId];
        
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
        
        LineInfo *routeLineInfo = self.menuSections[kSectionLines][indexPath.row];
        [destVC setRoute:routeLineInfo.route];
        
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
