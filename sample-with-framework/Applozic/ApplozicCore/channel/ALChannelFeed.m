//
//  ALChannelFeed.m
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALChannelFeed.h"
#import "ALConversationProxy.h"

@implementation ALChannelFeed

- (id)initWithJSONString:(NSString *)JSONString {
    [self parseMessage:JSONString];
    return self;
}

- (void)parseMessage:(id)jsonResponse {
    NSMutableArray *channelFeedArray = [NSMutableArray new];
    NSDictionary *channelFeedDictionary = [jsonResponse valueForKey:@"groupFeeds"];
    for (NSDictionary *channelDictionary in channelFeedDictionary) {
        ALChannel *channel = [[ALChannel alloc] initWithDictonary:channelDictionary];
        [channelFeedArray addObject:channel];
    }
    self.channelFeedsList = channelFeedArray;
    
    NSMutableArray *conversationProxyArray = [NSMutableArray new];
    
    NSDictionary *conversationProxyDictinoary = [jsonResponse valueForKey:@"conversationPxys"];
    for (NSDictionary *conversationDictionary in conversationProxyDictinoary) {
        ALConversationProxy *conversationProxy = [[ALConversationProxy alloc] initWithDictonary:conversationDictionary];
        [conversationProxyArray addObject:conversationProxy];
    }
    self.conversationProxyList = conversationProxyArray;
}

@end
