//
//  ASMapView.m
//  ASMapView
//
//  Created by Hasan on 6/4/14.
//  Copyright (c) 2014 AssembleLabs. All rights reserved.
//

#import "ASMapView.h"

typedef enum {
    ASMapViewTouchStateNormal,
    ASMapViewTouchStateZoomMode
} ASMapViewTouchState;

/*
 This indicates the amount of change in views display points via touch that
 triggers a zoom change
 */
NSInteger const kASMapViewTouchSensitivity = 0;
/*
 The base zoom factor is multiplied via velocity^2 to get the zoom factor
 */
double const kASMapViewBaseZoom = 1.05;

@interface ASMapView() <UIGestureRecognizerDelegate>

/**
 The location of a touch began event, used to check if a 2nd touch is receieved at the same location.
 */
@property (nonatomic, assign) CGPoint zoomTouchLocation;
/**
 The state of the view and if it should response to zoom panning
 */
@property (nonatomic, assign) ASMapViewTouchState zoomTouchState;

//@property (nonatomic, assign) NSInteger zoomMoveTouchCount;

-(void) applyZoom:(BOOL)increaseZoom;

@property (nonatomic, assign) BOOL hasFirstTouch;
@property (nonatomic, assign) CFAbsoluteTime firstTouchTime;

@end

@implementation ASMapView

-(void) layoutSubviews
{
    static dispatch_once_t onceToken = 0;
    __weak typeof(self) weakMe = self;
    dispatch_once(&onceToken, ^{
        [weakMe setZoomTouchLocation:CGPointMake(FLT_MAX, FLT_MAX)];
    });
}


#pragma mark touch handling

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] != 1) {
        return;
    }
    
    if (self.hasFirstTouch == false) {
        self.firstTouchTime = CFAbsoluteTimeGetCurrent();
        self.hasFirstTouch = true;
    } else {
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (fabs(now - self.firstTouchTime) < 0.4) {
            self.zoomTouchState = ASMapViewTouchStateZoomMode;
            self.hasFirstTouch = false;
        } else {
            self.firstTouchTime = CFAbsoluteTimeGetCurrent();
        }
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] != 1 || self.zoomTouchState != ASMapViewTouchStateZoomMode) {
        return;
    }
    
    UITouch* touch = [[touches allObjects] firstObject];
    CGPoint prevLocation = [touch previousLocationInView:self];
    CGPoint newLocation = [touch locationInView:self];
    CGFloat deltaYPoint = newLocation.y - prevLocation.y;
    
    if (fabs(deltaYPoint) > kASMapViewTouchSensitivity) {
        if (deltaYPoint < 0) {
            [self zoomOut];
        }
        else {
            [self zoomIn];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setZoomTouchState:ASMapViewTouchStateNormal];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setZoomTouchState:ASMapViewTouchStateNormal];
}


#pragma mark - Zoom controls

-(void) zoomIn
{
    [self applyZoom:YES];
}

-(void) zoomOut
{
    [self applyZoom:NO];
}

-(void) applyZoom:(BOOL)increaseZoom
{
    CGFloat currentWidth = [self bounds].size.width;
    CGFloat currentHeight = [self bounds].size.height;
    
    MKCoordinateRegion currentRegion = [self region];
    double latitudePerPoint = currentRegion.span.latitudeDelta / currentWidth;
    double longitudePerPoint = currentRegion.span.longitudeDelta / currentHeight;
    
    //quad the zoom at each level
    double zoomFactor = kASMapViewBaseZoom;
    
    double newLatitudePerPoint;
    double newLongitudePerPoint;
    
    if (increaseZoom) {
        newLatitudePerPoint = latitudePerPoint / zoomFactor;
        newLongitudePerPoint = longitudePerPoint / zoomFactor;
    } else {
        newLatitudePerPoint = latitudePerPoint * zoomFactor;
        newLongitudePerPoint = longitudePerPoint * zoomFactor;
    }
    
    CLLocationDegrees newLatitudeDelta = newLatitudePerPoint * currentWidth;
    CLLocationDegrees newLongitudeDelta = newLongitudePerPoint * currentHeight;
    
    if (newLatitudeDelta <= 90 && newLongitudeDelta <= 90) {
        MKCoordinateRegion mapRegion;
        mapRegion.center = self.centerCoordinate;
        mapRegion.span.latitudeDelta = newLatitudeDelta;
        mapRegion.span.longitudeDelta = newLongitudeDelta;
        [self setRegion:mapRegion animated:NO];
    }
}


@end

