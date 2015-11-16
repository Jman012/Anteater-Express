//
//  RouteTabView.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RoutesAndAnnounceDAO.h"
#import "RouteVehiclesDAO.h"
#import "RouteDefinitionDAO.h"
#import "StopArrivalPredictionDAO.h"

#import "ColorConverter.h"

#import "MapAnnotation.h"
#import "ImageAnnotationView.h"

#import "RouteTabView.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "AppDelegate.h"

#define METERS_PER_MILE 1609.344

RouteDefinitionDAO* routeDefDAO;
RouteVehiclesDAO* routeVehiclesDAO;
MKAnnotationView * lastClickedAnnotationView;

const double MAP_POINT_PADDING = 1000;
const double MAP_LENGTH_PADDING = MAP_POINT_PADDING * 2;

@interface RouteTabView ()

@end

@implementation RouteTabView


@synthesize mapview; //MapView
@synthesize routeData; //NSMutableDictionary
@synthesize routeStops;
@synthesize routePoints;
@synthesize routeVehicles;
@synthesize routeLine = _routeLine;
@synthesize routeLineView = _routeLineView;
@synthesize routeLineBackground = _routeLineBackground;
@synthesize routeLineViewBackground = _routeLineViewBackground;
@synthesize vehicleTimer;
@synthesize vehicleInitTimer;
@synthesize arrivalPredictionsTimer;
@synthesize arrivalPredictionsInitTimer;
//@synthesize progressInd;
//@synthesize m_activity;

//NSInteger selectedRouteID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self; 
}

- (void)viewDidLoad //Method called once
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    
    //Start Activity Indicator View
    //[self.view addSubview:self.progressInd];
    
    //Start loading spinner
//    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    /*spinner.center = CGPointMake(160, 240);
    spinner.tag = 12;
    [self.view addSubview:spinner];*/
  //  [spinner startAnimating];
    
    //Sets the NavBar title to the Route Name
    
    UINavigationBar* tabNavBar  = [[self navigationController] navigationBar];
    NSString* routeName         = [routeData objectForKey:@"Name"];
    
    NSString* viewName = @"Route Map : ";
    viewName = [viewName stringByAppendingString:routeName];
    self.trackedViewName = viewName;
    
    tabNavBar.topItem.title     = routeName;
    
    
    int stopSetID         = [[routeData objectForKey:@"StopSetId"] intValue];
    //Get Route Definition and Vehicle Information
    routeDefDAO           = [[RouteDefinitionDAO alloc] initWithStopID:stopSetID]; 
    routeVehiclesDAO      = [[RouteVehiclesDAO alloc] initWithStopID:stopSetID]; 
    
    //Load the route information into seperate arrays
    routePoints        = [routeDefDAO getRoutePoints];
    routeStops         = [routeDefDAO getRouteStops];
    routeVehicles      = [routeVehiclesDAO getRouteVehicles];
    
    //Vehicles initialized and then updated
    [self addVehicleAnnotations];
    [self updateVehicles]; 
    
    
    // create the overlay
	[self loadRoute];
	
	// add the overlay to the map
	if (nil != self.routeLineBackground) {
		[self.mapview addOverlay:self.routeLineBackground];
	}
	
	// add the overlay to the map
	if (nil != self.routeLine) {
		[self.mapview addOverlay:self.routeLine];
	}
    
	// zoom in on the route. 
	//[self zoomInOnRoute];
    
    //Timer to update vehicles every six seconds
  //  vehicleTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(updateVehiclesTimer:) userInfo:nil repeats: YES];
    
    //[self.progressInd removeFromSuperview];
}

- (void) updateVehiclesTimer: (NSTimer *) theTimer
{
    [self updateVehicles];
}
     
- (void) updateVehicles
{
    //NSLog(@"VEHICLES UPDATED");
    //Get updated vehicle positions
    int stopSetID           = [[routeData objectForKey:@"StopSetId"] intValue];
    routeVehiclesDAO        = [[RouteVehiclesDAO alloc] initWithStopID:stopSetID]; 
    routeVehicles           = [routeVehiclesDAO getRouteVehicles];
    
    for(MapAnnotation *annotation in mapview.annotations)
    {
        if([annotation isKindOfClass:[MapAnnotation class]])
        {
            if(annotation.annotationType == MapAnnotationTypeVehicle)
            {
                for(NSMutableDictionary *vehicle in routeVehicles)
                {
                    if([[vehicle objectForKey:@"Name"] isEqualToString:annotation.name]) //This annotation is equals this vehicle
                    {
                        [annotation willChangeValueForKey:@"title"];
                        [annotation willChangeValueForKey:@"subtitle"];
                        [annotation setNewVehicleDictionary:vehicle];
                        
                        //Updating the coordinate
                        CLLocationDegrees latitude;
                        CLLocationDegrees longitude;
                        
                        latitude  = [[vehicle objectForKey:@"Latitude"] doubleValue];
                        longitude = [[vehicle objectForKey:@"Longitude"] doubleValue];
                        
                        // create new coordinate
                        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                        
                        [annotation setCoordinate:coordinate];
                        //[annotation setVehiclePicture:vehicle];
                        
      //CODE WORKS EXCEPT FOR IMAGE BEING TOO LARGE
                        ImageAnnotationView* annotationView = (ImageAnnotationView*)[mapview viewForAnnotation: annotation]; 
                        //CGRect thumbnailRect = CGRectZero;
                        //thumbnailRect.size.width = 30;
                        //thumbnailRect.size.height = 18;
                        annotationView.image = [UIImage imageNamed:[annotation setVehiclePicture:vehicle]];
                        
                        [annotation didChangeValueForKey:@"title"];
                        [annotation didChangeValueForKey:@"subtitle"];

        //END WORKING CODE
                        
                        /*int kHeight = 16;
                        int kWidth  = 30;
                        int kBorder = 0;
                        annotationView.frame = CGRectMake(kBorder, kBorder, kWidth - 2 * kBorder, kWidth - 2 * kBorder);*/
                    }
                }
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated //Method called every time the view loads
{	
	[super viewWillAppear:YES];
    
//    int stopSetID           = [[routeData objectForKey:@"StopSetId"] intValue];
//    routeDefDAO           = [[RouteDefinitionDAO alloc] initWithStopID:stopSetID];
//    routeVehiclesDAO      = [[RouteVehiclesDAO alloc] initWithStopID:stopSetID];
//    
//    //Load the route information into seperate arrays
//    routePoints        = [routeDefDAO getRoutePoints];
//    routeStops         = [routeDefDAO getRouteStops];
//    routeVehicles      = [routeVehiclesDAO getRouteVehicles];
//    
//    //Vehicles initialized and then updated
//    [self addVehicleAnnotations];
//    [self updateVehicles];
//    
//    
//    // create the overlay
//	[self loadRoute];
//	
//	// add the overlay to the map
//	if (nil != self.routeLineBackground) {
//		[self.mapview addOverlay:self.routeLineBackground];
//	}
//	
//	// add the overlay to the map
//	if (nil != self.routeLine) {
//		[self.mapview addOverlay:self.routeLine];
//	}

    
    vehicleInitTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateVehiclesTimer:) userInfo:nil repeats: NO];
    vehicleTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(updateVehiclesTimer:) userInfo:nil repeats: YES];
    
    if(lastClickedAnnotationView != nil) //Restart timer if one was going on when the user left the screen
    {
        arrivalPredictionsTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateArrivalPredictionsTimer:) userInfo:nil repeats: NO];
    }
}

- (void) viewDidAppear:(BOOL)animated //Method called every time the view already appeared
{
    [super viewDidAppear:YES];
    // zoom in on the route.
	[self zoomInOnRoute];
}

// creates the route (MKPolyline) overlay, the overlay is actually added in the viewWillAppear function
-(void) loadRoute
{
	// while we create the route points, we will also be calculating the bounding box of our route
	// so we can easily zoom in on it. 
	MKMapPoint northEastPoint; 
	MKMapPoint southWestPoint; 
	
	// create a c array of points. 
	MKMapPoint* pointArr = malloc(sizeof(CLLocationCoordinate2D) * routePoints.count);
	
	for(int i = 0; i < routePoints.count; i++)
	{
        // break the string down even further to latitude and longitude fields. 
		NSMutableDictionary* currentPoint = [routePoints objectAtIndex:i];
        
		CLLocationDegrees latitude  = [[currentPoint objectForKey:@"Latitude"] doubleValue];
		CLLocationDegrees longitude = [[currentPoint objectForKey:@"Longitude"] doubleValue];
        
       // NSLog(@"Latitude: %f", [[currentPoint objectForKey:@"latitude"] doubleValue]); 
       // NSLog(@"Longitude: %f", [[currentPoint objectForKey:@"longitude"] doubleValue]);
        
		// create our coordinate and add it to the correct spot in the array 
		CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
		MKMapPoint point = MKMapPointForCoordinate(coordinate);
        
		
		//
		// adjust the bounding box
		//
		
		// if it is the first point, just use them, since we have nothing to compare to yet. 
		if (i == 0) {
			northEastPoint = point;
			southWestPoint = point;
		}
		else 
		{
			if (point.x > northEastPoint.x) 
				northEastPoint.x = point.x;
			if(point.y > northEastPoint.y)
				northEastPoint.y = point.y;
			if (point.x < southWestPoint.x) 
				southWestPoint.x = point.x;
			if (point.y < southWestPoint.y) 
				southWestPoint.y = point.y;
		}
        
		pointArr[i] = point;
        
	}
	
	// create the polyline based on the array of points. 
	self.routeLine = [MKPolyline polylineWithPoints:pointArr count:routePoints.count];
	
	// create the polyline background based on the array of points. 
	self.routeLineBackground = [MKPolyline polylineWithPoints:pointArr count:routePoints.count];
    
    [self addStopAnnotations];
    
   // NSLog(@"south.x : %@, north.y: %@", southWestPoint, northEastPoint);
    
    _routeRect = MKMapRectMake(southWestPoint.x - MAP_POINT_PADDING, southWestPoint.y - MAP_POINT_PADDING, northEastPoint.x - southWestPoint.x + MAP_LENGTH_PADDING, northEastPoint.y - southWestPoint.y + MAP_LENGTH_PADDING);
    
    
	// clear the memory allocated earlier for the points
	free(pointArr);
	
}

- (void)addStopAnnotations
{
    for(NSMutableDictionary *stop in routeStops)
    {
    
        // create the rest of the annotations
        MapAnnotation* annotation = nil;
	
        // create the start annotation and add it to the array
        annotation = [[MapAnnotation alloc] initWithAnnotationType:MapAnnotationTypeStop
														dictionary:stop];
        [mapview addAnnotation:annotation];
        
    }
	
    [self updateStopArrivalPredictions];
	// center and size the map view on the region computed by our route annotation. 
	//[mapview setRegion:routeAnnotation.region];
}

- (void)addVehicleAnnotations
{
    for(NSMutableDictionary *vehicle in routeVehicles)
    {
        // create the rest of the annotations
        MapAnnotation* annotation = nil;
    
        // create the image annotation
        annotation = [[MapAnnotation alloc] initWithAnnotationType:MapAnnotationTypeVehicle
                                                      dictionary:vehicle];
	
        [mapview addAnnotation:annotation];
    }
}

//Method to zoom in on the route itself
-(IBAction) zoomInOnRoute
{
	[self.mapview setVisibleMapRect:_routeRect animated:YES];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    [vehicleTimer invalidate];
    [vehicleInitTimer invalidate];
    
    //Precautionary incase user closes view with a callout open
    [arrivalPredictionsTimer invalidate];
    [arrivalPredictionsInitTimer invalidate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)setMapType:(id)sender  
{
    switch (((UISegmentedControl *)sender).selectedSegmentIndex) {
        case 0:
            mapview.mapType = MKMapTypeStandard;
            break;
        case 1:
            mapview.mapType = MKMapTypeSatellite;
            break;
        case 2:
            mapview.mapType = MKMapTypeHybrid; 
            break;
            
        default:
            break;
    }
}

- (IBAction)setUsersLocation 
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = mapview.userLocation.coordinate;
    
    //The amount of north-to-south distance (measured in degrees) to display on the map. Unlike longitudinal distances, which vary based on the latitude, one degree of latitude is always approximately 111 kilometers (69 miles).
    mapRegion.span.latitudeDelta = 0.005;  
    
    //The amount of east-to-west distance (measured in degrees) to display for the map region. The number of kilometers spanned by a longitude range varies based on the current latitude. For example, one degree of longitude spans a distance of approximately 111 kilometers (69 miles) at the equator but shrinks to 0 kilometers at the poles.
    mapRegion.span.longitudeDelta = 0.005; 
    
    [mapview setRegion:mapRegion animated: YES];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
	MKOverlayView* overlayView = nil;
	
	if(overlay == self.routeLine)
	{
		//if we have not yet created an overlay view for this overlay, create it now. 
		if(nil == self.routeLineView)
		{
			self.routeLineView = [[MKPolylineView alloc] initWithPolyline:self.routeLine];
            
            //Get Color from Database to set route color
            NSString* routeHexColor;
            
            ColorConverter *colorConvert = [[ColorConverter alloc] init];
            
            if(routeData != nil) //Set button to selectedRoute if it was found
            {
                routeHexColor = [routeData valueForKey:@"ColorHex"];
            }
            else { //There was no valid route  selected, set to Red as backup
                routeHexColor = @"FF0000";
            }
            
            
            UIColor * routeColor = [colorConvert colorWithHexString:routeHexColor];
            
			self.routeLineView.strokeColor = routeColor;
			self.routeLineView.lineWidth = 4;
		}
		
		overlayView = self.routeLineView;
		
	}
    else if(overlay == self.routeLineBackground)
	{
		//if we have not yet created an overlay view for this overlay, create it now. 
		if(nil == self.routeLineViewBackground)
		{
			self.routeLineViewBackground = [[MKPolylineView alloc] initWithPolyline:self.routeLine];
            
			self.routeLineViewBackground.strokeColor = [UIColor blackColor];
			self.routeLineViewBackground.lineWidth = 5;
		}
		
		overlayView = self.routeLineViewBackground;
		
	}
	
	return overlayView;
	
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView* annotationView = nil;
	
	if([annotation isKindOfClass:[MapAnnotation class]])
	{
		// determine the type of annotation, and produce the correct type of annotation view for it.
		MapAnnotation* mapAnnotation = (MapAnnotation*)annotation;
		if(mapAnnotation.annotationType == MapAnnotationTypeStop)
		{
            NSString* identifier = @"Pin";
			MKPinAnnotationView* pin = (MKPinAnnotationView*)[self.mapview dequeueReusableAnnotationViewWithIdentifier:identifier];
			
			if(nil == pin)
			{
				pin = [[MKPinAnnotationView alloc] initWithAnnotation:mapAnnotation reuseIdentifier:identifier];
			}
			
			//[pin setPinColor:(annotation.annotationType == MapAnnotationTypeVehicle) ? MKPinAnnotationColorRed : MKPinAnnotationColorGreen];
            [pin setPinColor:MKPinAnnotationColorRed];
            
            pin.animatesDrop = YES;
			
			annotationView = pin;
		}
		else if(mapAnnotation.annotationType == MapAnnotationTypeVehicle)
		{
            NSString* identifier = @"Image";
			
			ImageAnnotationView* imageAnnotationView = (ImageAnnotationView*)[self.mapview dequeueReusableAnnotationViewWithIdentifier:identifier];
			if(nil == imageAnnotationView)
			{
				imageAnnotationView = [[ImageAnnotationView alloc] initWithAnnotation:mapAnnotation reuseIdentifier:identifier];	
				//imageAnnotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			}
            
            //UIView *leftCAV = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 23, 23)];
            
            /*if([[[mapAnnotation dictionary] objectForKey:@"HasAPC"] intValue] == 1)
            {
                NSString * doorOpenText = ([[[mapAnnotation dictionary] objectForKey:@"DoorStatus"] intValue] == 1) ? @"Yes" : @"No";
                NSString * apcPercentageText = [[mapAnnotation dictionary] objectForKey:@"APCPercentage"];
                
                UILabel *doorStatusLabel = [[UILabel alloc]init];
                doorStatusLabel.text = doorOpenText;
                    
                UILabel *percentFullLabel = [[UILabel alloc]init];
                percentFullLabel.text = apcPercentageText;
                    
                [leftCAV addSubview : doorStatusLabel];
                [leftCAV addSubview : percentFullLabel];
            }
                
            UILabel *lastUpdatedLabel = [[UILabel alloc]init];
            lastUpdatedLabel.text = [[mapAnnotation dictionary] objectForKey:@"Updated"];
                
            [leftCAV addSubview : lastUpdatedLabel];
            
            imageAnnotationView.leftCalloutAccessoryView = leftCAV;*/
            
			annotationView = imageAnnotationView;
		}
        
        
		
		[annotationView setEnabled:YES];
		[annotationView setCanShowCallout:YES];
	}
	
	/*else if([annotation isKindOfClass:[RouteAnnotation class]])
	{
		CSRouteAnnotation* routeAnnotation = (CSRouteAnnotation*) annotation;
		
		annotationView = [_routeViews objectForKey:routeAnnotation.routeID];
		
		if(nil == annotationView)
		{
			CSRouteView* routeView = [[[CSRouteView alloc] initWithFrame:CGRectMake(0, 0, _mapView.frame.size.width, _mapView.frame.size.height)] autorelease];
            
			routeView.annotation = routeAnnotation;
			routeView.mapView = _mapView;
			
			[_routeViews setObject:routeView forKey:routeAnnotation.routeID];
			
			annotationView = routeView;
		}
	}*/
	
	return annotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    lastClickedAnnotationView = view;
    
    arrivalPredictionsInitTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateArrivalPredictionsTimer:) userInfo:nil repeats: NO];
    arrivalPredictionsTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateArrivalPredictionsTimer:) userInfo:nil repeats: YES];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    [arrivalPredictionsTimer invalidate];
    [arrivalPredictionsInitTimer invalidate];
    
    lastClickedAnnotationView = nil;
}

- (void) updateArrivalPredictionsTimer: (NSTimer *) theTimer
{
    [self updateStopArrivalPredictions];
}

- (void) updateStopArrivalPredictions
{
    id <MKAnnotation> annotationToBeUpdated = [lastClickedAnnotationView annotation];
    
        if([annotationToBeUpdated isKindOfClass:[MapAnnotation class]])
        {
            MapAnnotation* annotation = (MapAnnotation*)annotationToBeUpdated;
            if(annotation.annotationType == MapAnnotationTypeStop)
            {
                StopArrivalPredictionDAO* arrivalDAO = [[StopArrivalPredictionDAO alloc] initWithStopSetID:annotation.stopSetIDParam andStopID:annotation.stopIDParam];
                
                //NSLog(@"Arrival Predictions Updated for StopID %d", annotation.stopIDParam);
                
                [annotation willChangeValueForKey:@"subtitle"];
                        
                NSArray * arrivalPredictions = [[arrivalDAO getArrivalTimes] valueForKey:@"Predictions"];
                        
                [annotation setNewArrivalPredictions:arrivalPredictions];
                        
                [annotation didChangeValueForKey:@"subtitle"];
            }
        }
}


//- (UIActivityIndicatorView *) progressInd
//{
//    if(progressInd == nil)
//    {
//        CGRect frame = CGRectMake(self.view.frame.size.width/2-15, self.view.frame.size.height/2-15, 30, 30);
//        progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
//        [progressInd startAnimating];
//        progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//        [progressInd sizeToFit];
//        progressInd.autoresizingMask =  (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
//        progressInd.tag = 1;
//    }
//    return progressInd;
//}

@end
