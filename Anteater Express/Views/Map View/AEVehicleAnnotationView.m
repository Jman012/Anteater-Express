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
    self.image = [self.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIGraphicsBeginImageContextWithOptions(self.image.size, NO, self.image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rect = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
    
    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, self.image.CGImage);
    
    CGContextClipToMask(context, rect, self.image.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSoftLight);
    [self.tintColor setFill];
    CGContextFillRect(context, rect);
    
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
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
