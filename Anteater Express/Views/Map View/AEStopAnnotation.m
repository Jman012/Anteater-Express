//
//  AEStopAnnotation.m
//  Anteater Express
//
//  Created by James Linnell on 12/21/15.
//
//

#import "AEStopAnnotation.h"

#import "AEDataModel.h"
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

- (NSString *)makeSubtitleForArrivalDict:(NSDictionary<NSNumber*,NSArray<Arrival*>*> *)arrivalDict {
    
    NSMutableArray *comps = [NSMutableArray array];
    [arrivalDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *routeId, NSArray<Arrival*> *arrivals, BOOL *stop) {
        NSString *result = @"";
        NSString *abbreviation = [AEDataModel.shared routeForId:routeId].shortName;
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@ in ", abbreviation]];
        
        NSMutableArray *times = [NSMutableArray array];
        for (Arrival *arrival in arrivals) {
            NSNumber *minutes = [NSNumber numberWithDouble:round(arrival.secondsToArrival.doubleValue / 60.0)];
            [times addObject:[minutes stringValue]];
        }
        
        result = [result stringByAppendingString:[times componentsJoinedByString:@", "]];
        result = [result stringByAppendingString:@" mins."];
        
        [comps addObject:result];
    }];
    
    return [comps componentsJoinedByString:@" "];
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
