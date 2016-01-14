//
//  AEVehicleAnnotation.m
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import "AEVehicleAnnotation.h"

@implementation AEVehicleAnnotation

- (instancetype)initWithVehicleDictionary:(NSDictionary *)theVehicleDictionary {
    if (self = [super init]) {
        self.vehicleDictionary = theVehicleDictionary;
    }
    return self;
}

- (void)setVehicleDictionary:(NSDictionary *)vehicleDictionary {
    _vehicleDictionary = vehicleDictionary;
    [self updateVehiclePicture];
    self.coordinate = CLLocationCoordinate2DMake([vehicleDictionary[@"Latitude"] doubleValue], [vehicleDictionary[@"Longitude"] doubleValue]);
}

- (void)updateVehiclePicture {
    NSInteger doorStatus = [[self.vehicleDictionary objectForKey:@"DoorStatus"] integerValue];
    NSString *heading = [self.vehicleDictionary objectForKey:@"Heading"];
    
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
    NSString *apcPercentageText = [self.vehicleDictionary objectForKey:@"APCPercentage"];
    NSString *name = [self.vehicleDictionary objectForKey:@"Name"];
    return [NSString stringWithFormat:@"Bus %@ - %@%% Full", name, apcPercentageText];
}

- (NSString *)subtitle {
    return [NSString stringWithFormat:@"Last Updated: %@", [self.vehicleDictionary objectForKey:@"Updated"]];
}

@end
