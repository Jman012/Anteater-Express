//
//  AppDelegate.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const AENotificationAppDidBecomeActive;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) NSInteger *selectedRouteID;

@end
