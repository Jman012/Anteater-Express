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
#import "Stop.h"
#import "Route.h"
#import "Arrival.h"

@interface AEStopAnnotation : NSObject <MKAnnotation>

// MKAnnotation protocol
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;

// Custom
@property (nonatomic, strong) Stop *stop;
@property (nonatomic, strong) NSMutableArray<Route*> *routes;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSArray*> *arrivalPredictions; // StopSetId -> @[Predictions]

- (instancetype)initWithStop:(Stop *)stop;
- (void)addNewDictionary:(NSDictionary *)newDict;
- (NSArray<NSNumber*> *)stopSetIds;
- (NSString *)formattedSubtitleForArrivalList:(NSArray<Arrival*> *)arrivalList abbreviation:(NSString *)abbreviation;

@end
