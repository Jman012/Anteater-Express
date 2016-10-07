//
//  MapViewController.h
//  Anteater Express
//
//  Created by James Linnell on 11/22/15.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <Google/Analytics.h>
#import "ASMapView.h"

#import "AEDataModel.h"

@interface MapViewController : GAITrackedViewController <MKMapViewDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, AEDataModelDelegate>

- (void)setMapType:(MKMapType)newType;

@end
