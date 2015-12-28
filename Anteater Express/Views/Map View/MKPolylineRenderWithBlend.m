//
//  MKPolylineRenderWithBlend.m
//  Anteater Express
//
//  Created by James Linnell on 12/26/15.
//
//

#import "MKPolylineRenderWithBlend.h"

@implementation MKPolylineRenderWithBlend

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    
    CGContextSetBlendMode(context, kCGBlendModeDarken);
    [super drawMapRect:mapRect zoomScale:zoomScale inContext:context];
    
    CGContextRestoreGState(context);
}

@end
