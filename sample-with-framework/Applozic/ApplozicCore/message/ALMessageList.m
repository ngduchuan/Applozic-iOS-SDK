//
//  ALMessageList.m
//  ChatApp
//
//  Created by Devashish on 22/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALChannel.h"
#import "ALLogger.h"
#import "ALMessage.h"
#import "ALMessageList.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserDetail.h"

@implementation ALMessageList


- (id)initWithJSONString:(NSString *)syncMessageResponse {
    [self parseMessagseArray:syncMessageResponse];
    return self;
}

- (id)initWithJSONString:(NSString *)syncMessageResponse andWithUserId:(NSString *)userId andWithGroup:(NSNumber *)groupId {
    
    self.groupId = groupId;
    self.userId = userId;
    [self parseMessagseArray:syncMessageResponse];
    return self;
}

- (void)parseMessagseArray:(id)messageJson {
    NSMutableArray *messagesArray = [NSMutableArray new];
    NSMutableArray *userDetailArray = [NSMutableArray new];
    NSMutableArray *conversationProxyList = [NSMutableArray new];

    NSDictionary *messagesDictionary = [messageJson valueForKey:@"message"];
    ALSLog(ALLoggerSeverityInfo, @"MESSAGES_DICT_COUNT :: %lu",(unsigned long)messagesDictionary.count);
    if (messagesDictionary.count == 0 &&
        !self.userId &&
        !self.groupId) {
        ALSLog(ALLoggerSeverityInfo, @"NO_MORE_MESSAGES");
        [ALUserDefaultsHandler setFlagForAllConversationFetched: YES];
    }
    
    for (NSDictionary *messageDictionary in messagesDictionary) {
        ALMessage *message = [[ALMessage alloc] initWithDictonary:messageDictionary];
        [messagesArray addObject:message];
    }
    self.messageList = messagesArray;
    
    NSDictionary *userDetailsDictionary = [messageJson valueForKey:@"userDetails"];

    for (NSDictionary *userDetailDictionary in userDetailsDictionary) {
        ALUserDetail *userDetail = [[ALUserDetail alloc] initWithDictonary:userDetailDictionary];
        [userDetailArray addObject:userDetail];
    }
    
    NSDictionary *conversationsProxyDictionary = [messageJson valueForKey:@"conversationPxys"];
    
    for (NSDictionary *conversationProxyDictionary in conversationsProxyDictionary) {
        ALConversationProxy *conversationProxy = [[ALConversationProxy alloc] initWithDictonary:conversationProxyDictionary];
        conversationProxy.userId = self.userId;
        conversationProxy.groupId = self.groupId;
        [conversationProxyList addObject:conversationProxy];
    }
    
    self.conversationPxyList = conversationProxyList;
    self.userDetailsList = userDetailArray;

}

@end
