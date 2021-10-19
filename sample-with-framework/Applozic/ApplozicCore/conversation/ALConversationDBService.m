//
//  ALConversationDBService.m
//  Applozic
//
//  Created by Devashish on 27/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALConversationDBService.h"
#import "ALDBHandler.h"
#import "ALLogger.h"

@implementation ALConversationDBService

- (void)insertConversationProxy:(NSMutableArray *)proxyArray {
    if (proxyArray == nil || !proxyArray.count) {
        return;
    }

    ALDBHandler *databaseaHandler = [ALDBHandler sharedInstance];
    
    for (ALConversationProxy *conversationProxy in proxyArray) {
        [self createConversationProxy:conversationProxy];
    }

    NSError *error = [databaseaHandler saveContext];
    if (error) {
        ALSLog(ALLoggerSeverityError, @"ERROR: InsertConversationProxy METHOD %@",error);
    }
    
}

- (void)insertConversationProxyTopicDetails:(NSMutableArray*)proxyArray {

    ALDBHandler *databaseaHandler = [ALDBHandler sharedInstance];
    
    for (ALConversationProxy *conversationProxy in proxyArray) {
        DB_ConversationProxy *dbConversationProxy = [self getConversationProxyByKey:conversationProxy.Id];
        if (!dbConversationProxy) {
            dbConversationProxy.topicDetailJson = conversationProxy.topicDetailJson;
        }
    }
    
    NSError *error = [databaseaHandler saveContext];
    if (error) {
        ALSLog(ALLoggerSeverityError, @"ERROR: TopicDetails Insert METHOD %@",error);
    } else {
        ALSLog(ALLoggerSeverityInfo, @"SUCCESS: TopicDetails Insertion in DB ");
    }

}

- (DB_ConversationProxy *)createConversationProxy:(ALConversationProxy *)conversationProxy {
    ALDBHandler *databaseaHandler = [ALDBHandler sharedInstance];
    DB_ConversationProxy *dbConversationProxy = [self getConversationProxyByKey:conversationProxy.Id];
    if (!dbConversationProxy) {
        dbConversationProxy = (DB_ConversationProxy*)[databaseaHandler insertNewObjectForEntityForName:@"DB_ConversationProxy"];
    }
    if (dbConversationProxy) {
        dbConversationProxy.iD=conversationProxy.Id;
        dbConversationProxy.topicId = conversationProxy.topicId;
        dbConversationProxy.groupId = conversationProxy.groupId;
        dbConversationProxy.created = [NSNumber numberWithBool:conversationProxy.created];
        dbConversationProxy.closed = [NSNumber numberWithBool:conversationProxy.closed];
        dbConversationProxy.userId = conversationProxy.userId;
        dbConversationProxy.topicDetailJson = conversationProxy.topicDetailJson;
    }

    return dbConversationProxy;
}


- (DB_ConversationProxy *)getConversationProxyByKey:(NSNumber *)Id {
    ALDBHandler *databaseaHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *conversationEntity = [databaseaHandler entityDescriptionWithEntityForName:@"DB_ConversationProxy"];
    if (conversationEntity) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"iD = %@",Id];
        [fetchRequest setEntity:conversationEntity];
        [fetchRequest setPredicate:predicate];
        NSError *fetchError = nil;
        NSArray *result = [databaseaHandler executeFetchRequest:fetchRequest withError:&fetchError];
        if (result.count) {
            DB_ConversationProxy *proxy = [result objectAtIndex:0];
            return proxy;
        }
    }
    return nil;
}

- (NSArray*)getConversationProxyListFromDBForUserID:(NSString *)userId {
    ALDBHandler *databaseaHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *conversationEntity = [databaseaHandler entityDescriptionWithEntityForName:@"DB_ConversationProxy"];

    if (conversationEntity) {
        NSPredicate *predicate;
        if (userId) {
            predicate = [NSPredicate predicateWithFormat:@"userId = %@",userId];
            [fetchRequest setEntity:conversationEntity];
            [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[predicate]]];
            NSError *fetchError = nil;
            NSArray *result = [databaseaHandler executeFetchRequest:fetchRequest withError:&fetchError];
            if (result.count) {
                return result;
            }
        }
    }
    return nil;
}

- (NSArray*)getConversationProxyListFromDBForUserID:(NSString *)userId
                                         andTopicId:(NSString *)topicId {
    
    ALDBHandler *databaseaHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *conversationEntity = [databaseaHandler entityDescriptionWithEntityForName:@"DB_ConversationProxy"];

    if (conversationEntity) {
        NSPredicate *predicate;
        if (userId) {
            predicate = [NSPredicate predicateWithFormat:@"userId == %@ && topicId == %@",userId,topicId];
            [fetchRequest setEntity:conversationEntity];
            [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[predicate]]];
            NSError *fetchError = nil;

            NSArray *result = [databaseaHandler executeFetchRequest:fetchRequest withError:&fetchError];
            if (result.count) {
                return result;
            }
        }
    }
    return nil;
}

- (NSArray*)getConversationProxyListFromDBWithChannelKey:(NSNumber *)channelKey {
    
    ALDBHandler *databaseaHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *conversationEntity = [databaseaHandler entityDescriptionWithEntityForName:@"DB_ConversationProxy"];

    if (conversationEntity) {
        NSPredicate *predicate;
        if (channelKey != nil) {
            predicate = [NSPredicate predicateWithFormat:@"groupId = %@",channelKey];
            [fetchRequest setEntity:conversationEntity];
            [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[predicate]]];
            NSError *fetchError = nil;
            NSArray *result = [databaseaHandler executeFetchRequest:fetchRequest withError:&fetchError];
            if (result.count) {
                return result;
            }
        }
    }
    return nil;
}

@end
