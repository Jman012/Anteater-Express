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
#import <Google/Analytics.h>
#import "ASMapView.h"

#import "AEDataModel.h"

@interface MapViewController : GAITrackedViewController <MKMapViewDelegate, UIGestureRecognizerDelegate, SWRevealViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, AEDataModelDelegate>

- (void)setAllRoutesArray:(NSArray *)allRoutesArray;
- (void)showNewRoute:(NSNumber *)theId;
- (void)removeRoute:(NSNumber *)theId;
- (void)clearAllRoutes;

- (void)setMapType:(MKMapType)newType;

@end
