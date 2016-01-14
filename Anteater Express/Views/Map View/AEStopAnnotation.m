//
//  AEStopAnnotation.m
//  Anteater Express
//
//  Created by James Linnell on 12/21/15.
//
//

#import "AEStopAnnotation.h"

#import "ColorConverter.h"

@implementation AEStopAnnotation

- (instancetype)initWithDictionary:(NSDictionary *)initialRouteStopDictionary {
    
    if (self = [super init]) {
        
        CLLocationDegrees latitude  = [[initialRouteStopDictionary objectForKey:@"Latitude"] doubleValue];
        CLLocationDegrees longitude = [[initialRouteStopDictionary objectForKey:@"Longitude"] doubleValue];
        // create our coordinate
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
        self.stopId = [initialRouteStopDictionary objectForKey:@"StopId"];
        self.title = [initialRouteStopDictionary objectForKey:@"Name"]; // Name should be same for all dicts
        
        // Not sure if we need this yet.
        //_userData           = @"shuttle_E_moving.png"; //Sets default incase the heading is not set
        
        // Set the initial dictionary. More might be added
        _dictionaries = [NSMutableArray array];
        [self addNewDictionary:initialRouteStopDictionary];
        
    }
    
    return self;
}

- (void)addNewDictionary:(NSDictionary *)newDict {
    // This will make sure all new dicts added have the same stopId,
    // otherwise they shouldnt be added here.
    
    NSNumber *newStopId = newDict[@"StopId"];
    for (NSDictionary *curDict in self.dictionaries) {
        if ([newStopId isEqualToNumber:curDict[@"StopId"]] == false) {
            NSLog(@"Error: adding new dictionary to stop annotation with mismatching stopId's.");
            NSLog(@"-> Existing stopId: %@, new stopId: %@", curDict[@"StopId"], newStopId);
            return;
        }
    }
    
    // If we make it here, we're good.
    [_dictionaries addObject:newDict];
}

- (NSString *)subtitle {
    // Copied from the original
    if(self.arrivalPredictions != nil)
    {
        //subtitle = @"Arriving in ";
        NSString *subtitle = @"";
        for(int i = 0; i < [self.arrivalPredictions count]; i++)
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
            
            subtitle = [subtitle stringByAppendingString:[[[self.arrivalPredictions objectAtIndex:i] valueForKey:@"BusName"] stringValue]];
            
            NSString* minutesTillArrival = [[[self.arrivalPredictions objectAtIndex:i] valueForKey:@"Minutes"] stringValue];
            
            if([minutesTillArrival isEqualToString: @"0"])
            {
                subtitle = [subtitle stringByAppendingString:@" arriving "];
            }
            else
            {
                subtitle = [subtitle stringByAppendingString:@" in "];
                
                subtitle = [subtitle stringByAppendingString:[[[self.arrivalPredictions objectAtIndex:i] valueForKey:@"Minutes"] stringValue]];
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
        return subtitle;
    }
    else
    {
        return [NSString stringWithFormat:@"Arrival Predictions Loading..."];
    }

}

- (void)setNewArrivalPredictions:(NSArray *)newPredictions
{
    self.arrivalPredictions = newPredictions;
}

@end
