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

- (NSArray<NSNumber*> *)stopSetIds {
    NSMutableArray *retArray = [NSMutableArray array];
    [self.dictionaries enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
        [retArray addObject:dict[@"StopSetId"]];
    }];
    return retArray;
}

- (BOOL)shouldShowSubtitle {
    // If UIStackView available, it'll use the detail callout accessory view
    return !NSClassFromString(@"UIStackView");
}

- (NSString *)subtitle {
    if ([self shouldShowSubtitle] == false) {
        return nil;
    }
    
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
        return [NSString stringWithFormat:@"Arrival Predictions Loading..."];
    }

}

- (NSString *)formattedSubtitleForStopSetId:(NSNumber *)stopSetId abbreviation:(NSString *)abbreviation {
    __block NSString *subtitle = abbreviation;
    
    NSArray *predictions = self.arrivalPredictions[stopSetId];
    
    subtitle = [subtitle stringByAppendingString:@" Line"];
    
    [predictions enumerateObjectsUsingBlock:^(NSDictionary *predictionDict, NSUInteger idx, BOOL *stopInner) {
        subtitle = [subtitle stringByAppendingString:@"\n"];
        subtitle = [subtitle stringByAppendingString:@"  Bus "];
        subtitle = [subtitle stringByAppendingString:[predictionDict[@"BusName"] stringValue]];
        subtitle = [subtitle stringByAppendingString:@"\t"];
        
        NSString* minutesTillArrival = [predictionDict[@"Minutes"] stringValue];
        if([minutesTillArrival isEqualToString: @"0"])
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
