//
//  AEVehicleAnnotation.m
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import "AEVehicleAnnotation.h"

#import "Utilities.h"

@implementation AEVehicleAnnotation

- (instancetype)initWithVehicle:(Vehicle *)vehicle route:(Route *)route {
    if (self = [super init]) {
        self.route = route;
        self.vehicle = vehicle;
    }
    return self;
}

- (void)setVehicle:(Vehicle *)vehicle {
    _vehicle = vehicle;
    [self updateVehiclePicture];
    self.coordinate = CLLocationCoordinate2DMake(vehicle.latitude.doubleValue, vehicle.longitude.doubleValue);
}

- (void)updateVehiclePicture {
    NSInteger doorStatus = self.vehicle.doorStatus.boolValue;
    NSString *heading = self.vehicle.heading;
    
    if (doorStatus == 1)
    {
        if ([heading isEqualToString:@"N"])
        {
            self.vehiclePicture = @"shuttle_N_stopped.png";
        }
        else if ([heading isEqualToString:@"NE"])
        {
            self.vehiclePicture = @"shuttle_NE_stopped.png";
        }
        else if ([heading isEqualToString: @"NW"])
        {
            self.vehiclePicture = @"shuttle_NW_stopped.png";
        }
        else if ([heading isEqualToString: @"S"])
        {
            self.vehiclePicture = @"shuttle_S_stopped.png";
        }
        else if ([heading isEqualToString: @"SE"])
        {
            self.vehiclePicture = @"shuttle_SE_stopped.png";
        }
        else if ([heading isEqualToString: @"SW"])
        {
            self.vehiclePicture = @"shuttle_SW_stopped.png";
        }
        else if ([heading isEqualToString: @"W"])
        {
            self.vehiclePicture = @"shuttle_W_stopped.png";
        }
        else if ([heading isEqualToString: @"E"])
        {
            self.vehiclePicture = @"shuttle_E_stopped.png";
        }
    }
    else
    {
        if ([heading isEqualToString: @"N"])
        {
            self.vehiclePicture = @"shuttle_N_moving.png";
        }
        else if ([heading isEqualToString: @"NE"])
        {
            self.vehiclePicture = @"shuttle_NE_moving.png";
        }
        else if ([heading isEqualToString: @"NW"])
        {
            self.vehiclePicture = @"shuttle_NW_moving.png";
        }
        else if ([heading isEqualToString: @"S"])
        {
            self.vehiclePicture = @"shuttle_S_moving.png";
        }
        else if ([heading isEqualToString: @"SE"])
        {
            self.vehiclePicture = @"shuttle_SE_moving.png";
        }
        else if ([heading isEqualToString: @"SW"])
        {
            self.vehiclePicture = @"shuttle_SW_moving.png";
        }
        else if ([heading isEqualToString: @"W"])
        {
            self.vehiclePicture = @"shuttle_W_moving.png";
        }
        else if ([heading isEqualToString: @"E"])
        {
            self.vehiclePicture = @"shuttle_E_moving.png";
        }
    }
}

- (NSString *)title {
    //NSString * doorOpenText = ([[_dictionary objectForKey:@"DoorStatus"] intValue] == 1) ? @"Yes" : @"No";
    NSString *name = self.vehicle.name;
    NSString *line = self.route.shortName;
    return [NSString stringWithFormat:@"%@ Line - Bus %@", line, name];
}

- (NSString *)subtitle {

    NSString *updatedTime = self.vehicle.updated;
    NSString *basetime = [updatedTime substringToIndex:updatedTime.length - 1];
    NSString *period = [updatedTime substringFromIndex:updatedTime.length - 1];
    NSString *newString;
    if ([period isEqualToString:@"A"]) {
        newString = [NSString stringWithFormat:@"%@ AM", basetime];
    } else if ([period isEqualToString:@"P"]) {
        newString = [NSString stringWithFormat:@"%@ PM", basetime];
    } else {
        newString = nil;
    }
    
    if (newString == nil) {
        return [NSString stringWithFormat:@"Last Updated: %@", updatedTime];
    } else {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"h:mm:ss a";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"PDT"];
        NSDate *theDate = [formatter dateFromString:newString];
        NSDateComponents *timeComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:theDate];
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
        NSDateComponents *newComponents = [[NSDateComponents alloc] init];
        newComponents.year = dateComponents.year;
        newComponents.month = dateComponents.month;
        newComponents.day = dateComponents.day;
        newComponents.hour = timeComponents.hour;
        newComponents.minute = timeComponents.minute;
        newComponents.second = timeComponents.second;
        NSDate* finalDate = [[NSCalendar currentCalendar] dateFromComponents:newComponents];

        NSString *timeAgoString = [Utilities dateDisplayStringFromDate:finalDate];
        return [NSString stringWithFormat:@"Updated %@", timeAgoString];
    }
}

@end
