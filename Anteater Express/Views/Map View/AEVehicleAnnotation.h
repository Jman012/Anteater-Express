//
//  AEVehicleAnnotation.h
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "AEDataModel.h"

@interface AEVehicleAnnotation : NSObject <MKAnnotation>

// MKAnnotation protocol
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;

// Custom
// Not an array like in AEStopAnnotation because buses are 1-1 with routes.
@property (nonatomic, strong) Vehicle *vehicle;
@property (nonatomic, strong) NSString *vehiclePicture;
@property (nonatomic, strong) Route *route;

- (instancetype)initWithVehicle:(Vehicle *)vehicle route:(Route *)route;


@end
