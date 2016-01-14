//
//  MapControlInfo.m
//  Anteater Express
//
//  Created by James Linnell on 12/20/15.
//
//

#import "MapControlInfo.h"

@implementation MapControlInfo

- (instancetype)initWithSelection:(NSInteger)theSelection cellIdentifier:(NSString *)theCellIdentifier {
    if (self = [super initWithCellIdentifer:theCellIdentifier]) {
        self.selection = theSelection;
    }
    return self;
}

@end
