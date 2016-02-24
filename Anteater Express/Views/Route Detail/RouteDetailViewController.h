//
//  RouteDetailViewController.h
//  Anteater Express
//
//  Created by James Linnell on 2/22/16.
//
//

#import <UIKit/UIKit.h>

@interface RouteDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (void)setRoute:(NSDictionary *)route;

@end
