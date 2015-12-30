//
//  AEStopAnnotation.h
//  Anteater Express
//
//  Created by James Linnell on 12/21/15.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "AEStopAnnotationView.h"

@interface AEStopAnnotation : NSObject <MKAnnotation>

// MKAnnotation protocol
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;

// Custom
@property (nonatomic, strong, readonly) NSMutableArray *dictionaries;
@property (nonatomic, strong) NSNumber *stopId;
@property (nonatomic, strong) NSArray *arrivalPredictions;

- (instancetype)initWithDictionary:(NSDictionary *)initialRouteStopDictionary;
- (void)addNewDictionary:(NSDictionary *)newDict;
- (void)setNewArrivalPredictions:(NSArray *)newPredictions;

@end
