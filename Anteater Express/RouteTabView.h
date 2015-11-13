//
//  RouteTabView.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ParentCustomViewController.h"

@interface RouteTabView : ParentCustomViewController <MKMapViewDelegate>
{
    
    // the data representing the route points. 
	MKPolyline* _routeLineBackground;
    
	// the view we create for the line on the map
	MKPolylineView* _routeLineViewBackground;
    
    // the data representing the route points. 
	MKPolyline* _routeLine;
    
	// the view we create for the line on the map
	MKPolylineView* _routeLineView;
	
	// the rect that bounds the loaded points
	MKMapRect _routeRect;
}
extern const double MAP_POINT_PADDING;

extern const double MAP_LENGTH_PADDING;

@property (strong, nonatomic) IBOutlet MKMapView *mapview;

@property (strong, nonatomic) MKPolyline* routeLineBackground;

@property (strong, nonatomic) MKPolylineView* routeLineViewBackground;

@property (strong, nonatomic) MKPolyline* routeLine;

@property (strong, nonatomic) MKPolylineView* routeLineView;

@property (strong, nonatomic) IBOutlet NSMutableDictionary *routeData;

@property (weak, nonatomic) IBOutlet NSArray *routeStops;

@property (weak, nonatomic) IBOutlet NSArray *routePoints;

@property (weak, nonatomic) IBOutlet NSArray *routeVehicles;

@property (nonatomic) NSTimer* vehicleTimer;

@property (nonatomic) NSTimer* vehicleInitTimer;

@property (nonatomic) NSTimer* arrivalPredictionsTimer;

@property (nonatomic) NSTimer* arrivalPredictionsInitTimer;


//Progress Indicator Function
//- (UIActivityIndicatorView *) progressInd;

//Three option button to change between standard map, satellite, and hybrid views
- (IBAction)setMapType:(id)sender;

// uses the computer geo coordinates of the users device and zooms in on the map to their location
- (IBAction)setUsersLocation;

// load the points of the route from the data source, in this case
// a CSV file. 
- (void) loadRoute;

// use the computed _routeRect to zoom in on the route. 
- (IBAction) zoomInOnRoute;

@end
