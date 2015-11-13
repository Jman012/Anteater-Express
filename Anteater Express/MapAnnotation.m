//
//  MapAnnotation.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

@synthesize coordinate     = _coordinate;
@synthesize annotationType = _annotationType;
@synthesize userData       = _userData;
@synthesize url            = _url;
@synthesize name;
@synthesize stopIDParam;
@synthesize stopSetIDParam;
@synthesize arrivalPredictions;

-(id) initWithAnnotationType:(MapAnnotationType) annotationType
				   dictionary:(NSMutableDictionary*)dictionary
{
	self = [super init];
    CLLocationDegrees latitude;
    CLLocationDegrees longitude;
    
    if(annotationType == MapAnnotationTypeVehicle)
    {
        latitude  = [[dictionary objectForKey:@"Latitude"] doubleValue];
        longitude = [[dictionary objectForKey:@"Longitude"] doubleValue];
    }
    else if(annotationType == MapAnnotationTypeStop)
    {
        latitude  = [[dictionary objectForKey:@"Latitude"] doubleValue];
        longitude = [[dictionary objectForKey:@"Longitude"] doubleValue];
        
        stopIDParam = [[dictionary objectForKey:@"StopId"] intValue];
        stopSetIDParam = [[dictionary objectForKey:@"StopSetId"] intValue];
    }
    
    // create our coordinate
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    NSString* tempName;
    
    if(annotationType == MapAnnotationTypeStop)
	{
		tempName = [dictionary objectForKey:@"Name"];
	}
    else if(annotationType == MapAnnotationTypeVehicle)
    {
        tempName = [dictionary objectForKey:@"Name"];
    }
    
    name = tempName;
    
	_coordinate         = coordinate;
	_dictionary         = dictionary;
	_annotationType     = annotationType;
    _userData           = @"shuttle_E_moving.png"; //Sets default incase the heading is not set

    if(annotationType == MapAnnotationTypeVehicle)
        [self setVehiclePicture: _dictionary];
    
	return self;
}

- (NSString*) setVehiclePicture: (NSMutableDictionary *) newDictionary
{
   // NSLog(@"%i", [[newDictionary objectForKey:@"DoorStatus"] intValue]);
   // NSLog(@"%@", [newDictionary objectForKey:@"Heading"]);
   // NSLog(@"%f", [[newDictionary objectForKey:@"Latitude"] doubleValue]);
   // NSLog(@"%f", [[newDictionary objectForKey:@"Longitude"] doubleValue]);
                  
    if ([[newDictionary objectForKey:@"DoorStatus"] intValue] == 1)
    {
        if ([[newDictionary objectForKey:@"Heading"] isEqualToString:@"N"])
        {
            _userData = @"shuttle_N_stopped.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString:@"NE"])
        {
            _userData = @"shuttle_NE_stopped.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"NW"])
        {
            _userData = @"shuttle_NW_stopped.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"S"])
        {
            _userData = @"shuttle_S_stopped.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"SE"])
        {
            _userData = @"shuttle_SE_stopped.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"SW"])
        {
            _userData = @"shuttle_SW_stopped.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"W"])
        {
            _userData = @"shuttle_W_stopped.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"E"])
        {
            _userData = @"shuttle_E_stopped.png";
        }
    }
    else
    {
        if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"N"])
        {
            _userData = @"shuttle_N_moving.png";
        }    
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"NE"])
        {
            _userData = @"shuttle_NE_moving.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"NW"])
        {
            _userData = @"shuttle_NW_moving.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"S"])
        {
            _userData = @"shuttle_S_moving.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"SE"])
        {
            _userData = @"shuttle_SE_moving.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"SW"])
        {
            _userData = @"shuttle_SW_moving.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"W"])
        {
            _userData = @"shuttle_W_moving.png";
        }
        else if ([[newDictionary objectForKey:@"Heading"] isEqualToString: @"E"])
        {
            _userData = @"shuttle_E_moving.png";
        }
    }
    
    //NSLog(@"%@", _userData);
    
    return _userData;
}

- (NSMutableDictionary *)dictionary
{
	return _dictionary;
}

- (NSString *)title
{
	if(_annotationType == MapAnnotationTypeStop)
	{
		return [NSString stringWithFormat:@"%@", name];
	}
    else if(_annotationType == MapAnnotationTypeVehicle)
    {
        //NSLog(@"%@", [_dictionary objectForKey:@"HasAPC"]);
        if([[_dictionary objectForKey:@"HasAPC"] intValue] == 1)
        {
            //NSString * doorOpenText = ([[_dictionary objectForKey:@"DoorStatus"] intValue] == 1) ? @"Yes" : @"No";
            NSString * apcPercentageText = [_dictionary objectForKey:@"APCPercentage"];
            return [NSString stringWithFormat:@"Bus %@ - %@%% Full", name, apcPercentageText];
        }
        else 
        {
            return [NSString stringWithFormat:@"Bus %@", name]; 
        }
    }
    else 
    {
        return [NSString stringWithFormat:@"%@", name];
    }
}

- (MapAnnotationType)getAnnotationType
{
    return (_annotationType);
}

- (NSString *)subtitle
{
	NSString* subtitle = nil;
	
	if(_annotationType == MapAnnotationTypeStop)
	{
		if(arrivalPredictions != nil)
        {
            //subtitle = @"Arriving in ";
            subtitle = @"";
            for(int i = 0; i < [arrivalPredictions count]; i++)
            {
                if(i > 1) //Don't show more than 2 arrival predictions
                {
                    break;
                }
                
                if(i != 0)
                {
                    subtitle = [subtitle stringByAppendingString:@"and "];
                }
                
                subtitle = [subtitle stringByAppendingString:@"Bus "];
                
                subtitle = [subtitle stringByAppendingString:[[[arrivalPredictions objectAtIndex:i] valueForKey:@"BusName"] stringValue]];
                
                NSString* minutesTillArrival = [[[arrivalPredictions objectAtIndex:i] valueForKey:@"Minutes"] stringValue];
                
                if([minutesTillArrival isEqualToString: @"0"])
                {
                    subtitle = [subtitle stringByAppendingString:@" arriving "];
                }
                else 
                {
                    subtitle = [subtitle stringByAppendingString:@" in "];
                    
                    subtitle = [subtitle stringByAppendingString:[[[arrivalPredictions objectAtIndex:i] valueForKey:@"Minutes"] stringValue]];
                    if([minutesTillArrival isEqualToString: @"1"])
                    {
                        subtitle = [subtitle stringByAppendingString:@" minute "];
                    }
                    else 
                    {
                        subtitle = [subtitle stringByAppendingString:@" minutes "];
                    }
                }
            }
        }
        else 
        {
            subtitle = [NSString stringWithFormat:@"Arrival Predictions Loading..."];
        }
	}
    else if(_annotationType == MapAnnotationTypeVehicle)
    {
        subtitle = [NSString stringWithFormat:@"Last Updated: %@", [_dictionary objectForKey:@"Updated"]];
    }
	
	return subtitle;
}

- (void)setNewVehicleDictionary:(NSMutableDictionary *)newDictionary
{
    _dictionary = newDictionary;
}

- (void)setNewArrivalPredictions:(NSArray *)newPredictions
{
    arrivalPredictions = newPredictions;
}

@end
