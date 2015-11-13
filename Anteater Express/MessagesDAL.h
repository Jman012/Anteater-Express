//
//  MessagesDAL.h
//  Anteater Express
//
//  Created by Andrew Beier on 8/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessagesDAL : NSObject
{

}

-(id) initWithArray:(NSArray *) identifierArray basedOnType:(BOOL) isAnnouncements forOneRoute:(BOOL) isSingleRoute;

-(BOOL) isRead:(NSString *) identifier;

-(void) markAsRead:(NSString *) identifier;

-(int) unreadMessages;

@end
