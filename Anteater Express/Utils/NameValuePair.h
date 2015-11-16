//
//  NameValuePair.h
//  NSHttpPost
//
//  Created by Andrew Beier on 2/25/12.
//  Copyright (c) 2012 University of California, Irvine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NameValuePair: NSObject
{
    NSString * _name;
    NSString * _value;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* value;

-(id) initWithName:(NSString *) name andValue:(NSString *) value;
@end
