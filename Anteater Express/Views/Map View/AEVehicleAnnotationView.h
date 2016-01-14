//
//  AEVehicleAnnotationView.h
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import <MapKit/MapKit.h>

@interface AEVehicleAnnotationView : MKAnnotationView

@property (nonatomic, strong) UIColor *tintColor;

- (void)setVehicleImage:(NSString *)vehiclePictureString;

@end
