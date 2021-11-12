//
//  ALConversationService.h
//  Applozic
//
//  Created by Devashish on 27/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALConversationClientService.h"
#import "ALConversationDBService.h"
#import "ALConversationProxy.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALConversationService : NSObject

@property (nonatomic, strong) ALConversationClientService *conversationClientService;

@property (nonatomic, strong) ALConversationDBService *conversationDBService;

- (ALConversationProxy * _Nullable)getConversationByKey:(NSNumber *)conversationKey;

- (void)addConversations:(NSMutableArray *)conversations;

- (ALConversationProxy * _Nullable)convertAlConversationProxy:(DB_ConversationProxy *)dbConversation;

- (NSMutableArray * _Nullable)getConversationProxyListForUserID:(NSString *)userId;

- (NSMutableArray * _Nullable)getConversationProxyListForChannelKey:(NSNumber *)channelKey;

- (void)createConversation:(ALConversationProxy *)conversationProxy
            withCompletion:(void(^)(NSError * _Nullable error, ALConversationProxy * _Nullable conversationProxy))completion;

- (void)fetchTopicDetails:(NSNumber *)conversationProxyID withCompletion:(void(^)(NSError * _Nullable error, ALConversationProxy * _Nullable conversationProxy))completion;

@end
NS_ASSUME_NONNULL_END
