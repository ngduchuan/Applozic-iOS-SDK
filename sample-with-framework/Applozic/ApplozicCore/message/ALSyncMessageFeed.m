//
//  ALSyncMessageFeed.m
//  ChatApp
//
//  Created by Devashish on 20/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALMessage.h"
#import "ALSyncMessageFeed.h"

@implementation ALSyncMessageFeed


- (id)initWithJSONString:(NSString *)syncMessageResponse {
    
    self.lastSyncTime = [syncMessageResponse valueForKey:@"lastSyncTime"];
    NSMutableArray *messages = [syncMessageResponse valueForKey:@"messages"];
    [self parseMessagseArray:messages];
    self.deliveredMessageKeys = [syncMessageResponse valueForKey:@"deliveredMessageKeys"];
    return self;
}

- (void)parseMessagseArray:(id)messages {
    NSMutableArray *messagesArray = [NSMutableArray new];
    for (NSDictionary *messageDictionary in messages) {
        ALMessage *message = [[ALMessage alloc] initWithDictonary:messageDictionary];
        [messagesArray addObject:message];
    }
    self.messagesList = messagesArray;
}

@end
