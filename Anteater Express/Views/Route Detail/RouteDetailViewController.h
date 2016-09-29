//
//  RouteDetailViewController.h
//  Anteater Express
//
//  Created by James Linnell on 2/22/16.
//
//

#import <UIKit/UIKit.h>
#import <Google/Analytics.h>

#import "Route.h"

@interface RouteDetailViewController : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate>

- (void)setRoute:(Route *)route;

@end
