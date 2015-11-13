//
//  SelectRoute.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectRoute : UIViewController <UITableViewDelegate, UITableViewDataSource>

//- (UIColor *) colorWithHexString: (NSString *) stringToConvert;

@property (weak, nonatomic) IBOutlet NSArray *routesData;
@property (strong, nonatomic) IBOutlet UITableView *routesList;

@end
