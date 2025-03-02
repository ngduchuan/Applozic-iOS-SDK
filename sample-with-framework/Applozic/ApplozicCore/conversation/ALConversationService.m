//
//  ALConversationService.m
//  Applozic
//
//  Created by Devashish on 27/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALConversationClientService.h"
#import "ALConversationDBService.h"
#import "ALConversationProxy.h"
#import "ALConversationService.h"
#import "ALLogger.h"
#import "DB_ConversationProxy.h"

@implementation ALConversationService

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupServices];
    }
    return self;
}

#pragma mark - Setup service

- (void)setupServices {
    self.conversationClientService = [[ALConversationClientService alloc] init];
    self.conversationDBService = [[ALConversationDBService alloc] init];
}

#pragma mark - Get conversation by key

- (ALConversationProxy *)getConversationByKey:(NSNumber *)conversationKey {
    
    DB_ConversationProxy *dbConversation = [self.conversationDBService getConversationProxyByKey:conversationKey];
    if (dbConversation == nil) {
        return nil;
    }
    return [self convertAlConversationProxy:dbConversation];
}

#pragma mark - Add conversation

- (void)addConversations:(NSMutableArray *)conversations {
    [self.conversationDBService insertConversationProxy:conversations];
}

- (void)addTopicDetails:(NSMutableArray *)conversations {
    [self.conversationDBService insertConversationProxyTopicDetails:conversations];
}

- (ALConversationProxy *)convertAlConversationProxy:(DB_ConversationProxy *)dbConversation {
    
    ALConversationProxy *conversationProxy = [[ALConversationProxy alloc] init];
    conversationProxy.groupId = dbConversation.groupId;
    conversationProxy.userId = dbConversation.userId;
    conversationProxy.topicDetailJson = dbConversation.topicDetailJson;
    conversationProxy.topicId = dbConversation.topicId;
    conversationProxy.Id = dbConversation.iD;
    return conversationProxy;
}

#pragma mark - Get conversation list for UserId

- (NSMutableArray *)getConversationProxyListForUserID:(NSString *)userId {
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *conversationArray = [self.conversationDBService getConversationProxyListFromDBForUserID:userId];
    if (!conversationArray.count) {
        return result;
    }
    for (DB_ConversationProxy *dbConversation in conversationArray) {
        ALConversationProxy *conversation = [self convertAlConversationProxy:dbConversation];
        [result addObject:conversation];
    }
    
    return result;
}

#pragma mark - Get conversation list for UserId and topicId

- (NSMutableArray*)getConversationProxyListForUserID:(NSString *)userId
                                          andTopicId:(NSString *)topicId {
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *conversationArray = [self.conversationDBService getConversationProxyListFromDBForUserID:userId andTopicId:topicId];
    if (!conversationArray.count) {
        return result;
    }
    for (DB_ConversationProxy *dbConversation in conversationArray) {
        ALConversationProxy *conversation = [self convertAlConversationProxy:dbConversation];
        [result addObject:conversation];
    }
    return result;
}

- (NSMutableArray *)getConversationProxyListForChannelKey:(NSNumber *)channelKey {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *conversationArray = [self.conversationDBService getConversationProxyListFromDBWithChannelKey:channelKey];
    
    for (DB_ConversationProxy *dbConversation in conversationArray) {
        ALConversationProxy *conversation = [self convertAlConversationProxy:dbConversation];
        [result addObject:conversation];
    }
    return  result;
}

#pragma mark - Create conversation

- (void)createConversation:(ALConversationProxy *)conversationProxy
            withCompletion:(void(^)(NSError *error, ALConversationProxy *conversationProxy))completion {
    
    
    NSArray *conversationArray = [[NSArray alloc] initWithArray:[self getConversationProxyListForUserID:conversationProxy.userId andTopicId:conversationProxy.topicId]];
    
    
    if (conversationArray.count != 0) {
        ALConversationProxy *existingConversationProxy = conversationArray[0];
        ALSLog(ALLoggerSeverityInfo, @"Conversation Proxy List Found In DB :%@",existingConversationProxy.topicDetailJson);
        completion(nil, conversationProxy);
    } else {
        [self.conversationClientService createConversation:conversationProxy withCompletion:^(NSError *error, ALConversationCreateResponse *response) {
            
            if (!error) {
                NSMutableArray *proxyArr = [[NSMutableArray alloc] initWithObjects:response.alConversationProxy, nil];
                [self addConversations:proxyArr];
            } else {
                ALSLog(ALLoggerSeverityError, @"ALConversationService : Error creatingConversation ");
            }
            completion(error, response.alConversationProxy);
        }];
    }
    
}

#pragma mark - Fetch topic detail

- (void)fetchTopicDetails:(NSNumber *)conversationProxyID
           withCompletion:(void(^)(NSError *error, ALConversationProxy *conversationProxy))completion {
    
    ALConversationProxy *conversationProxy = [self getConversationByKey:conversationProxyID];
    
    if (conversationProxy != nil) {
        ALSLog(ALLoggerSeverityInfo, @"Conversation/Topic Alerady exists");
        completion(nil, conversationProxy);
        return;
    }
    
    [self.conversationClientService fetchTopicDetails:conversationProxyID andCompletion:^(NSError *error, ALAPIResponse *response) {
        
        if (!error) {
            ALSLog(ALLoggerSeverityInfo, @"ALAPIResponse: FETCH TOPIC DEATIL  %@",response);
            ALConversationProxy *conversationProxy = [[ALConversationProxy alloc] initWithDictonary:response.response];
            NSMutableArray *conversationProxyArray = [[NSMutableArray alloc] initWithObjects:conversationProxy, nil];
            [self addConversations:conversationProxyArray];
            completion(nil, conversationProxy);
        } else {
            ALSLog(ALLoggerSeverityError, @"ALAPIResponse : Error FETCHING TOPIC DEATILS ");
            completion(error, nil);
        }
    }];
}
@end
