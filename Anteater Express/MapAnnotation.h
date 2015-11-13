//
//  MapAnnotation.h
//  Anteater Express
//
//  Created by Andrew Beier on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

// types of annotations for which we will provide annotation views. 
typedef enum {
	MapAnnotationTypeStop       = 0,
	MapAnnotationTypeVehicle    = 1
} MapAnnotationType;

@interface MapAnnotation : NSObject <MKAnnotation>
{
	CLLocationCoordinate2D  _coordinate;
	MapAnnotationType       _annotationType;
	NSMutableDictionary*    _dictionary;
	NSString*               _userData;
	NSURL*                  _url;
}

-(id) initWithAnnotationType:(MapAnnotationType) annotationType
				   dictionary:(NSMutableDictionary*)dictionary;

- (MapAnnotationType)getAnnotationType;
- (NSString *) setVehiclePicture: (NSMutableDictionary *) newDictionary;
- (NSMutableDictionary *)dictionary;
- (void)setNewVehicleDictionary:(NSMutableDictionary *)newDictionary;
- (void)setNewArrivalPredictions:(NSArray *)newPredictions;


@property (nonatomic) MapAnnotationType annotationType;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (strong, nonatomic) NSString* userData;
@property (strong, nonatomic) NSString* name;
@property int stopSetIDParam;
@property int stopIDParam;
@property (strong, nonatomic) NSURL* url;
@property (weak, nonatomic) IBOutlet NSArray* arrivalPredictions;

@end
