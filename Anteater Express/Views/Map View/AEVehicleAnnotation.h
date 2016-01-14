//
//  AEVehicleAnnotation.h
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AEVehicleAnnotation : NSObject <MKAnnotation>

// MKAnnotation protocol
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;

// Custom
// Not an array like in AEStopAnnotation because buses are 1-1 with routes.
@property (nonatomic, strong) NSDictionary *vehicleDictionary;
@property (nonatomic, strong) NSNumber *stopSetId;
@property (nonatomic, strong) NSNumber *vehicleId;
@property (nonatomic, strong) NSString *vehiclePicture;

- (instancetype)initWithVehicleDictionary:(NSDictionary *)theVehicleDictionary;


@end
