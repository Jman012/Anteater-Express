//
//  ImageAnnotationView.m
//  Anteater Express
//
//  Created by Andrew Beier on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageAnnotationView.h"
#import "MapAnnotation.h"

#define kHeight 16
#define kWidth  30
#define kBorder 0

@implementation ImageAnnotationView

@synthesize imageView = _imageView;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	self.frame = CGRectMake(0, 0, kWidth, kHeight);
	self.backgroundColor = [UIColor clearColor];
	
	MapAnnotation* mapAnnotation = (MapAnnotation*)annotation;
	
	UIImage* image = [UIImage imageNamed:mapAnnotation.userData];
	//_imageView = [[UIImageView alloc]  initWithImage:image];
    _imageView = [[UIImageView alloc]  init];
    _imageView.image = image;
	
	//_imageView.frame = CGRectMake(kBorder, kBorder, kWidth - 2 * kBorder, kWidth - 2 * kBorder);
	[self addSubview:_imageView];
	
	return self;
	
}

- (void)updateAnnotationImage:(id <MKAnnotation>)annotation
{
    MapAnnotation* mapAnnotation = (MapAnnotation*)annotation;
	
	UIImage* image = [UIImage imageNamed:mapAnnotation.userData];
	UIImageView* tempImageView = [[UIImageView alloc] initWithImage:image];
	
	//tempImageView.frame = CGRectMake(kBorder, kBorder, kWidth - 2 * kBorder, kWidth - 2 * kBorder);
	_imageView = tempImageView;
    [self setImageView:tempImageView];
}

@end
