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

- (instancetype)initWithStop:(Stop *)stop {
    
    if (self = [super init]) {
        
        self.stop = stop;
        self.coordinate = CLLocationCoordinate2DMake(self.stop.latitude.doubleValue, self.stop.longitude.doubleValue);
        self.title = stop.name;
        self.routes = [NSMutableArray array];
    }
    
    return self;
}

- (BOOL)shouldShowSubtitle {
    // If UIStackView available, it'll use the detail callout accessory view
    return !NSClassFromString(@"UIStackView");
}

- (NSString *)subtitle {
    
    // Copied from the original
    if(self.arrivalPredictions != nil && self.arrivalPredictions.count > 0)
    {
        __block NSString *subtitle = @"";
        [self.arrivalPredictions enumerateKeysAndObjectsUsingBlock:^(NSNumber *stopSetId, NSArray *predictions, BOOL *stop) {
            for(int i = 0; i < [predictions count]; i++)
            {
                if(i > 1) //Don't show more than 2 arrival predictions
                {
                    *stop = true;
                }
                
                if(i != 0)
                {
                    subtitle = [subtitle stringByAppendingString:@"and "];
                }
                
                subtitle = [subtitle stringByAppendingString:@"Bus "];
                
                subtitle = [subtitle stringByAppendingString:[[[predictions objectAtIndex:i] valueForKey:@"BusName"] stringValue]];
                
                NSString* minutesTillArrival = [[[predictions objectAtIndex:i] valueForKey:@"Minutes"] stringValue];
                
                if([minutesTillArrival isEqualToString: @"0"])
                {
                    subtitle = [subtitle stringByAppendingString:@" arriving "];
                }
                else
                {
                    subtitle = [subtitle stringByAppendingString:@" in "];
                    
                    subtitle = [subtitle stringByAppendingString:[[[predictions objectAtIndex:i] valueForKey:@"Minutes"] stringValue]];
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
        }];
        return subtitle;
    }
    else
    {
        if ([self shouldShowSubtitle] == false) {
            return nil;
        } else {
            return [NSString stringWithFormat:@"Arrival Predictions Loading..."];
        }
    }

}

- (NSString *)formattedSubtitleForArrivalList:(NSArray<Arrival*> *)arrivalList abbreviation:(NSString *)abbreviation {
    __block NSString *subtitle = abbreviation;
    
    subtitle = [subtitle stringByAppendingString:@" Line"];
    
    [arrivalList enumerateObjectsUsingBlock:^(Arrival *arrival, NSUInteger idx, BOOL *stopInner) {
        subtitle = [subtitle stringByAppendingString:@"\n"];
        subtitle = [subtitle stringByAppendingString:@"  Bus "];
        subtitle = [subtitle stringByAppendingString:arrival.vehicleName];
        subtitle = [subtitle stringByAppendingString:@"\t"];
        
        NSNumber *minutes = [NSNumber numberWithDouble:round(arrival.secondsToArrival.doubleValue / 60.0)];
        NSString* minutesTillArrival = [minutes stringValue];
        if(arrival.secondsToArrival.doubleValue <= 0)
        {
            subtitle = [subtitle stringByAppendingString:@"arriving"];
        }
        else
        {
            subtitle = [subtitle stringByAppendingString:@"in "];
            
            subtitle = [subtitle stringByAppendingString:minutesTillArrival];
            subtitle = [subtitle stringByAppendingString:@" min"];
        }
    }];
    
    return subtitle;
}

@end
