//
//  AEVehicleAnnotationView.m
//  Anteater Express
//
//  Created by James Linnell on 1/13/16.
//
//

#import "AEVehicleAnnotationView.h"

@interface AEVehicleAnnotationView ()

@property (nonatomic, strong) NSMutableDictionary<NSString*, UIImage*> *vehiclePictures;

@end

@implementation AEVehicleAnnotationView

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        
    }
    return self;
}

- (void)setVehicleImage:(NSString *)vehiclePictureString {
    self.image = [self imageForString:vehiclePictureString];
}

- (UIImage *)imageForString:(NSString *)string {
    if ([self.vehiclePictures objectForKey:string] != nil) {
        return [self.vehiclePictures objectForKey:string];
    } else {
        UIImage *newImage = [UIImage imageNamed:string];
        self.vehiclePictures[string] = newImage;
        return newImage;
    }
}

@end
