//
//  MessagesDAL.m
//  Anteater Express
//
//  Created by Andrew Beier on 8/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessagesDAL.h"
#import "Utilities.h"

NSUserDefaults* preferences;
NSMutableArray* viewedIdList;
bool    isAnnouncementsBool;
NSString*  globalRouteId;
bool    isSingleRouteBool = true;

@implementation MessagesDAL

-(id) initWithArray:(NSArray *) identifierArray basedOnType:(BOOL) isAnnouncements forOneRoute:(BOOL) isSingleRoute
{
    if(self = [super init])
    {
        isAnnouncementsBool = isAnnouncements;
        isSingleRouteBool = isSingleRoute;
        preferences = [NSUserDefaults standardUserDefaults];
        [self createViewedList:( isAnnouncements ? VIEWED_ANNOUNCEMENTS : VIEWED_ROUTE_UPDATES )];
        [self removeExpired:identifierArray];
    }
    return self;
}

-(void) removeExpired:(NSArray*) identifierArray
{
    NSMutableArray* activeIdsArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [identifierArray count]; i++) //Go through all id's in inbound feed and add them to templist to compare against
    {
        if(isAnnouncementsBool)
        {
            [activeIdsArray addObject:[[[identifierArray objectAtIndex:i] valueForKey:@"GlobalAlertId"] stringValue]];
        }
        else 
        {
            NSString* routeID       = [[[identifierArray objectAtIndex:i] valueForKey:@"RouteId"] stringValue];
            NSString* routeAlertID  = [[[identifierArray objectAtIndex:i] valueForKey:@"RouteAlertId"] stringValue];
            NSString* objectString  = [routeID stringByAppendingString:@"_"];
            objectString  = [objectString stringByAppendingString:routeAlertID];
            
            if(i == 0)
            {
                globalRouteId = routeID;
            }
            
            [activeIdsArray addObject:objectString];
        }
        
    }
    
    NSMutableArray* discardedItems = [NSMutableArray array];
    
    for (int j = 0; j < [viewedIdList count]; j++) //Go through all viewed ids stored in memory (In temp array)
    {        
        NSArray* viewedIdUnderscoreArray = [[viewedIdList objectAtIndex:j] componentsSeparatedByString: @"_"];
       // NSArray* activeIdUnderscoreArray = [[activeIdsArray objectAtIndex:k] componentsSeparatedByString: @"_"];
        if(isSingleRouteBool && ![globalRouteId isEqual:[viewedIdUnderscoreArray objectAtIndex:0]]) //If it does not have the same routeId prefix then dont continue
        {
            break; 
        }
        
        //Go through viewedIdList and if it is not in the resultset of ids coming from the server(identifierArray), if so add to remove list it
        bool matchFound = false;
        for(int k = 0; k < [activeIdsArray count]; k++) //Go through all ids still coming from the server
        {
            if([[activeIdsArray objectAtIndex:k] isEqual:[viewedIdList objectAtIndex:j]])
            {
                matchFound = true;
            }
        }
        if(!matchFound) //If we didn't find a match add to removal
        {
            [discardedItems addObject:[viewedIdList objectAtIndex:j]];
        }
    }
    
    //Do the removes
    [viewedIdList removeObjectsInArray:discardedItems];
    
    [self saveViewedListToMemory:( isAnnouncementsBool ? VIEWED_ANNOUNCEMENTS : VIEWED_ROUTE_UPDATES )];
}

-(void) createViewedList:(NSString*) key
{
    NSString* viewedIds = [preferences stringForKey:key];
    
    if(!viewedIds) //If preferences returned null, initalize
    {
        viewedIds = [[NSString alloc] init];
    }
    
    viewedIdList = [[viewedIds componentsSeparatedByString:@"|"] mutableCopy];
    if(!viewedIdList) //If returned null array, then initalize
    {
        viewedIdList = [[NSMutableArray alloc] init];
    }
}

-(void) saveViewedListToMemory:(NSString*) keyToSave
{
    NSMutableString* stringToSave = [[NSMutableString alloc] init];
    for (int i = 0; i < [viewedIdList count]; i++) 
    {
        if(i != 0)
        {
            [stringToSave appendString:@"|"];
        }
        
        [stringToSave appendString:[viewedIdList objectAtIndex:i]];
    }
    
    [preferences setObject:stringToSave forKey:keyToSave];
}

-(BOOL) isRead:(NSString *) identifier
{
    bool isRead = false;
    
    for (int i = 0; i < [viewedIdList count]; i++) 
    {
        if([[viewedIdList objectAtIndex:i] isEqual: identifier])
        {
            //Found Ready Message
            isRead = true;
        }
    }
    return isRead;
}

-(void) markAsRead:(NSString *)identifier
{
    //Add to local Mutable Array if it doesn't already exist
    //Save it to memory if it wasn't read before
    if(![self isRead:identifier])
    {
        //Adding object to data structure to then be added to memory
        [viewedIdList addObject:identifier];
        
        [self saveViewedListToMemory:( isAnnouncementsBool ? VIEWED_ANNOUNCEMENTS : VIEWED_ROUTE_UPDATES )];
    }
}

-(int) unreadMessages
{ 
    return [viewedIdList count];
}


@end
