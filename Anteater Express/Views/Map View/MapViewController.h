//
//  MapViewController.h
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <SWRevealViewController/SWRevealViewController.h>

@interface MapViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate, SWRevealViewControllerDelegate, MKMapViewDelegate>

- (void)setAllRoutesArray:(NSArray *)allRoutesArray;
- (void)showNewRoute:(NSNumber *)theId;
- (void)removeRoute:(NSNumber *)theId;
- (void)clearAllRoutes;

- (void)setMapType:(MKMapType)newType;

@end
