//
//  ImageAnnotationView.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ImageAnnotationView : MKAnnotationView
{
	UIImageView* _imageView;
}

- (void)updateAnnotationImage:(id <MKAnnotation>)annotation;

@property (strong, nonatomic) UIImageView* imageView;

@end