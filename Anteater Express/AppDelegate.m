//
//  AppDelegate.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "Utilities.h"
#import "AEDataModel.h"
//#import "GAI.h"
#import <Google/Analytics.h>

NSString * const AENotificationAppDidBecomeActive = @"AENotificationAppDidBecomeActive";

@interface AppDelegate ()

@property (nonatomic, strong) id<GAITracker> tracker;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize selectedRouteID;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    // Optional: set debug to YES for extra debugging information.
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelError];
    // Create tracker instance.
    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-3170671-13"];
    
    // Override point for customization after application launch.

    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    NSInteger hasNetworkConnection = [Utilities checkNetworkStatus];
//    
//    if(hasNetworkConnection != 0)
//    {
//       // UIViewController *rootViewController = [[self window] rootViewController];
//        
//       // UINavigationController *navigation = [rootViewController navigationController];
//        UINavigationController *myNavCon = (UINavigationController*)self.window.rootViewController;
//        [myNavCon popToRootViewControllerAnimated:YES];
//    }
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
