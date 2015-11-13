//
//  NameValuePair.m
//  NSHttpPost
//
//  Created by Andrew Beier on 2/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import "NameValuePair.h"

@implementation NameValuePair

@synthesize name = _name;
@synthesize value = _value;

-(id) initWithName:(NSString *) nameStr andValue:(NSString *) valueStr
{
    if(self = [super init])
    {
        [self setName:nameStr];
        [self setValue:valueStr];
    }
    
    return self;
}
@end

