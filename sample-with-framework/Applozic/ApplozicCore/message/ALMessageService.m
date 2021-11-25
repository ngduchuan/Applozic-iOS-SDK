//
//  ALMessageService.m
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALApplozicSettings.h"
#import "ALConnectionQueueHandler.h"
#import "ALContactDBService.h"
#import "ALContactService.h"
#import "ALConversationService.h"
#import "ALDBHandler.h"
#import "ALHTTPManager.h"
#import "ALLogger.h"
#import "ALMessage.h"
#import "ALMessageDBService.h"
#import "ALMessageList.h"
#import "ALMessageService.h"
#import "ALMQTTConversationService.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALSendMessageResponse.h"
#import "ALSyncMessageFeed.h"
#import "ALUploadTask.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserDetail.h"
#import "ALUserService.h"
#import "ALUtilityClass.h"
#import "ApplozicClient.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>
#include <tgmath.h>
#import "ALVerification.h"

@interface ALMessageService  ()<ApplozicAttachmentDelegate>

@end

@implementation ALMessageService

static ALMessageClientService *alMsgClientService;

+ (ALMessageService *)sharedInstance {
    static ALMessageService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ALMessageService alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setUpServices];
    }
    return self;
}

#pragma mark - Setup service

- (void)setUpServices {
    self.messageClientService = [[ALMessageClientService alloc] init];
    self.userService = [[ALUserService alloc] init];
    self.channelService = [[ALChannelService alloc] init];
}

- (void)getMessagesListGroupByContactswithCompletionService:(void(^)(NSMutableArray *messages, NSError *error))completion {
    NSNumber *startTime = [ALUserDefaultsHandler isInitialMessageListCallDone] ? [ALUserDefaultsHandler getLastMessageListTime] : nil;

    [self.messageClientService getLatestMessageGroupByContact:[ALUserDefaultsHandler getFetchConversationPageSize]
                                                    startTime:startTime withCompletion:^(ALMessageList *messageList, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        [ALVerification verify:messageList.messageList != nil withErrorMessage:@"Get Messages list is nil."];

        if (messageList.messageList.count == 0) {
            completion(messageList.messageList, nil);
            return;
        }

        [self getMessageListForUserIfLastIsHiddenMessageinMessageList:messageList
                                                       withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {
            completion(messages, error);
        }];
    }];

}

- (void)getMessageListForUserIfLastIsHiddenMessageinMessageList:(ALMessageList *)messageList
                                                 withCompletion:(void (^)(NSMutableArray *messages,
                                                                          NSError *error,
                                                                          NSMutableArray *userDetailArray))completion {

    /*____If latest_message of a contact is HIDDEN MESSAGE OR MESSSAGE HIDE = TRUE, then get MessageList of that user from server___*/

    /// Also handle reply messages
    NSMutableArray<NSString *>* replyMessageKeys = [[NSMutableArray alloc] init];

    dispatch_group_t group = dispatch_group_create();

    for (ALMessage *message in messageList.messageList) {
        dispatch_group_enter(group);
        if (message.metadata) {
            NSString *key = [message.metadata valueForKey: AL_MESSAGE_REPLY_KEY];
            if (key) {
                [replyMessageKeys addObject: key];
            }
        }

        if (![message isHiddenMessage] && ![message isMsgHidden]) {
            dispatch_group_leave(group);
            continue;
        }

        NSNumber *time = message.createdAtTime;

        MessageListRequest *messageListRequest = [[MessageListRequest alloc] init];
        messageListRequest.userId = message.contactIds;
        messageListRequest.channelKey = message.groupId;
        messageListRequest.endTimeStamp = time;
        messageListRequest.conversationId = message.conversationId;
        messageListRequest.pageSize = @"20";

        [self getMessageListForUser:messageListRequest
                     withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue() , ^{
        [self fetchReplyMessages:replyMessageKeys withCompletion:^(NSMutableArray<ALMessage *> *messages) {
            completion(messageList.messageList, nil, nil);
        }];
    });
}

#pragma mark - Message thread

- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
               withCompletion:(void (^)(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray))completion {

    if (!messageListRequest) {
        NSError *messageListRequestError = [NSError errorWithDomain:@"Applozic"
                                                               code:1
                                                           userInfo:@{NSLocalizedDescriptionKey : @"MessageListRequest is nil"}];

        completion(nil, messageListRequestError, nil);
        return;
    }

    if (!messageListRequest.userId && !messageListRequest.channelKey) {
        NSError *requestParametersError = [NSError errorWithDomain:@"Applozic"
                                                              code:1
                                                          userInfo:@{NSLocalizedDescriptionKey : @"UserId and channelKey is nil"}];
        completion(nil, requestParametersError, nil);
        return;
    }

    //On Message List Cell Tap
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    NSMutableArray *messageList = [messageDBService getMessageListForContactWithCreatedAt:messageListRequest];

    NSString *chatId;
    if (messageListRequest.conversationId != nil) {
        chatId = [messageListRequest.conversationId stringValue];
    } else {
        chatId = messageListRequest.channelKey != nil ? [messageListRequest.channelKey stringValue] : messageListRequest.userId;
    }
    //Found Record in DB itself ...if not make call to server
    if (messageList.count > 0 && [ALUserDefaultsHandler isServerCallDoneForMSGList:chatId]) {
        completion(messageList, nil, nil);
        return;
    } else {
        ALSLog(ALLoggerSeverityInfo, @"Message thread fetching from server");
    }

    if (messageListRequest.channelKey != nil) {
        ALChannel *channel = [self.channelService getChannelByKey:messageListRequest.channelKey];
        if (channel) {
            messageListRequest.channelType = channel.type;
        }
    }

    ALContactDBService *contactDBService = [[ALContactDBService alloc] init];

    [self.messageClientService getMessageListForUser:messageListRequest
                                       withOpenGroup:messageListRequest.channelType == OPEN
                                      withCompletion:^(NSMutableArray *messages,
                                                       NSError *error,
                                                       NSMutableArray *userDetailArray) {


        if (error) {
            completion(nil, error, nil);
            return;
        }

        [contactDBService addUserDetails:userDetailArray];

        ALContactService *contactService = [ALContactService new];
        NSMutableArray *userNotPresentIds = [NSMutableArray new];
        NSMutableArray<NSString *>* replyMessageKeys = [[NSMutableArray alloc] init];

        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        for (int i = (int)messages.count - 1; i >= 0; i--) {
            ALMessage *message = messages[i];

            if ([message isHiddenMessage] && ![message isVOIPNotificationMessage]) {
                [messages removeObjectAtIndex:i];
            }

            if (message.to && ![contactService isContactExist:message.to]) {
                [userNotPresentIds addObject:message.to];
            }
            /// If its a reply message add the reply message key to array
            if (message.metadata) {
                NSString *replyKey = [message.metadata valueForKey:AL_MESSAGE_REPLY_KEY];
                if (replyKey && ![messageDBService getMessageByKey:@"key" value: replyKey] && ![replyMessageKeys containsObject: replyKey]) {
                    [replyMessageKeys addObject: replyKey];
                }
            }
        }
        /// Check if the key in reply array is present in messages
        for (int i = 0; i < messages.count; i++) {
            ALMessage *message = messages[i];
            if ([replyMessageKeys containsObject:message.key]) {
                [replyMessageKeys removeObject:message.key];
            }
        }

        /// Make server call for fetching reply messages
        [self fetchReplyMessages: replyMessageKeys withCompletion:^(NSMutableArray<ALMessage *> *replyMessages) {
            if (replyMessages && replyMessages.count > 0) {
                for (int i = 0; i < replyMessages.count; i++) {
                    if (replyMessages[i].to && ![contactService isContactExist:replyMessages[i].to]) {
                        [userNotPresentIds addObject: replyMessages[i].to];
                    }
                }
            }
            if (userNotPresentIds.count>0) {
                ALUserService *userService = [ALUserService new];
                [userService getUserDetails:userNotPresentIds withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                    completion(messages, error, userDetailArray);
                }];
            } else {
                completion(messages, error, userDetailArray);
            }
        }];
    }];
}

+ (void)getMessageListForContactId:(NSString *)contactIds
                           isGroup:(BOOL)isGroup
                        channelKey:(NSNumber *)channelKey
                    conversationId:(NSNumber *)conversationId
                        startIndex:(NSInteger)startIndex
                    withCompletion:(void (^)(NSMutableArray *))completion {
    int rp = 200;

    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *dbMessageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [dbMessageFetchRequest setFetchLimit:rp];
    NSPredicate *predicate1;
    if (conversationId && [ALApplozicSettings getContextualChatOption]) {
        predicate1 = [NSPredicate predicateWithFormat:@"conversationId = %d", [conversationId intValue]];
    } else if(isGroup) {
        predicate1 = [NSPredicate predicateWithFormat:@"groupId = %d", [channelKey intValue]];
    } else {
        predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@ && groupId = nil", contactIds];
    }

    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"deletedFlag == NO AND msgHidden == %@",@(NO)];
    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"contentType != %i",ALMESSAGE_CONTENT_HIDDEN];
    NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2,predicate3]];
    [dbMessageFetchRequest setPredicate:compoundPredicate];
    [dbMessageFetchRequest setFetchOffset:startIndex];
    [dbMessageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];

    NSArray *dbMessageArray = [databaseHandler executeFetchRequest:dbMessageFetchRequest withError:nil];

    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    if (dbMessageArray.count) {
        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        for (DB_Message *dbMessage in dbMessageArray) {
            ALMessage *message = [messageDBService createMessageEntity:dbMessage];
            [messageArray insertObject:message atIndex:0];
        }
    }
    completion(messageArray);
}

#pragma mark - Send message

- (void)sendMessages:(ALMessage *)message withCompletion:(void(^)(NSString *message, NSError *error)) completion {

    if (!message) {
        NSError *messageError = [NSError errorWithDomain:@"Applozic"
                                                    code:MessageNotPresent
                                                userInfo:@{NSLocalizedDescriptionKey : @"Empty message passed"}];

        completion(nil, messageError);
        return;
    }

    //DB insert if objectID is null
    DB_Message *dbMessage;
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateConversationTableNotification" object:message userInfo:nil];

    ALChannel *channel;
    if (message.groupId != nil) {
        ALChannelService *channelService = [[ALChannelService alloc] init];
        channel = [channelService getChannelByKey:message.groupId];
    }

    if (message.msgDBObjectId == nil) {
        ALSLog(ALLoggerSeverityInfo, @"Message not in DB new insertions.");
        if (channel) {
            if (channel.type != OPEN) {
                dbMessage = [messageDBService addMessage:message];
            }
        } else {
            dbMessage = [messageDBService addMessage:message];
        }
    } else {
        ALSLog(ALLoggerSeverityInfo, @"Message found in DB just getting it not inserting new one.");
        dbMessage = (DB_Message *)[messageDBService getMeesageById:message.msgDBObjectId];
    }
    //convert to dic
    NSDictionary *messageDictionary = [message dictionary];
    [self.messageClientService sendMessage:messageDictionary withCompletionHandler:^(id jsonResponse, NSError *error) {

        NSString *responseString = nil;

        if (!error) {
            ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
            ALSendMessageResponse *response = [[ALSendMessageResponse alloc] initWithJSONString:apiResponse.response];

            if (!response.isSuccess) {
                error = [NSError errorWithDomain:@"Applozic" code:1
                                        userInfo:[NSDictionary
                                                  dictionaryWithObject:@"Error in sending a message"
                                                  forKey:NSLocalizedDescriptionKey]];

            } else {
                if (channel) {
                    if (channel.type != OPEN || (dbMessage != nil && dbMessage.fileMetaInfo != nil)) {
                        message.msgDBObjectId = dbMessage.objectID;
                        [messageDBService updateMessageSentDetails:response.messageKey withCreatedAtTime:response.createdAt withDbMessage:dbMessage];

                    }
                } else {
                    message.msgDBObjectId = dbMessage.objectID;
                    [messageDBService updateMessageSentDetails:response.messageKey withCreatedAtTime:response.createdAt withDbMessage:dbMessage];
                }

                message.key = response.messageKey;
                message.sentToServer = YES;
                message.inProgress = NO;
                message.isUploadFailed= NO;
                message.status = [NSNumber numberWithInt:SENT];
            }

            if (self.delegate) {
                [self.delegate onMessageSent:message];
            }

        } else {
            ALSLog(ALLoggerSeverityError, @"Got error while sending message: %@", error.localizedDescription);
        }
        completion(responseString,error);
    }];

}

#pragma mark - Sync latest messages with delegate

+ (void) getLatestMessageForUser:(NSString *)deviceKeyString
                    withDelegate:(id<ApplozicUpdatesDelegate>)delegate
                  withCompletion:(void (^)(NSMutableArray *messages, NSError *error))completion {
    if (!alMsgClientService) {
        alMsgClientService = [[ALMessageClientService alloc] init];
    }

    @synchronized(alMsgClientService) {

        [alMsgClientService getLatestMessageForUser:deviceKeyString withCompletion:^(ALSyncMessageFeed *syncMessageFeed , NSError *error) {
            NSMutableArray *messageArray = nil;

            if (!error) {
                if (syncMessageFeed.deliveredMessageKeys.count > 0) {
                    [ALMessageService updateDeliveredReport:syncMessageFeed.deliveredMessageKeys withStatus:DELIVERED];
                }
                if (syncMessageFeed.messagesList.count > 0) {
                    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
                    messageArray = [messageDBService addMessageList:syncMessageFeed.messagesList skipAddingMessageInDb:NO];

                    NSMutableArray<NSString *> *messageKeys = [[NSMutableArray alloc] init];
                    for (ALMessage *message in syncMessageFeed.messagesList) {
                        if (message.metadata) {
                            NSString *replyMessageKey = [message.metadata valueForKey: AL_MESSAGE_REPLY_KEY];
                            if (replyMessageKey && ![messageDBService getMessageByKey:@"key" value:replyMessageKey]) {
                                [messageKeys addObject:replyMessageKey];
                            }
                        }
                    }
                    if (messageKeys.count > 0) {
                        [[ALMessageService sharedInstance] fetchReplyMessages:messageKeys withCompletion:^(NSMutableArray<ALMessage *> *messages) {
                            if (messages) {
                                [messageArray addObjectsFromArray:messages];
                            }
                            [self processMessages:messageArray delegate:delegate withCompletion:^(NSMutableArray *list) {
                                [ALUserDefaultsHandler setLastSyncTime:syncMessageFeed.lastSyncTime];
                                completion(list, nil);
                            }];
                        }];
                    } else {
                        [self processMessages:messageArray delegate:delegate withCompletion:^(NSMutableArray *list) {
                            [ALUserDefaultsHandler setLastSyncTime:syncMessageFeed.lastSyncTime];
                            completion(list, nil);
                        }];
                    }
                } else {
                    [ALUserDefaultsHandler setLastSyncTime:syncMessageFeed.lastSyncTime];
                    completion(messageArray, error);
                }
            } else {
                completion(messageArray, error);
            }
        }];
    }
}

+ (void)processMessages:(NSMutableArray *)messageArray
               delegate:(id<ApplozicUpdatesDelegate>)delegate
         withCompletion:(void(^)(NSMutableArray *))completion {
    ALUserService *userService = [[ALUserService alloc] init];
    [userService processContactFromMessages:messageArray withCompletion:^{

        BOOL syncChannel = NO;
        for (int i = (int)messageArray.count - 1; i>=0; i--) {
            ALMessage *message = messageArray[i];
            if ([message isHiddenMessage] && ![message isVOIPNotificationMessage]) {
                [messageArray removeObjectAtIndex:i];
            } else if (![message isToIgnoreUnreadCountIncrement]) {
                [self incrementContactUnreadCount:message];
            }

            if (message.groupId != nil && message.contentType == ALMESSAGE_CHANNEL_NOTIFICATION) {
                if ([message.metadata[@"action"] isEqual: @"4"]) {
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"CONVERSATION_DELETION"
                     object:message.groupId];
                }
                syncChannel = YES;
            }
            [self resetUnreadCountAndUpdate:message];
        }

        if (syncChannel) {
            ALChannelService *channelService = [[ALChannelService alloc] init];
            [channelService syncCallForChannelWithDelegate:delegate
                                            withCompletion:^(ALChannelSyncResponse *response, NSError *error) {

                [self postMessagesNotification:messageArray delegate:delegate];
                completion(messageArray);
            }];
        } else {
            [self postMessagesNotification:messageArray delegate:delegate];
            completion(messageArray);
        }
    }];
}

+(void)postMessagesNotification:(NSMutableArray *)messageArray
                       delegate:(id<ApplozicUpdatesDelegate>)delegate {

    if (delegate) {
        for (int i = (int)messageArray.count - 1; i>=0; i--) {
            ALMessage *message = messageArray[i];
            if (![message isHiddenMessage] && ![message isVOIPNotificationMessage] && delegate) {
                if ([message.type isEqual: AL_OUT_BOX]) {
                    [delegate onMessageSent: message];
                } else {
                    [delegate onMessageReceived: message];
                }
            }
        }
    }

    if (messageArray.count) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_MESSAGE_NOTIFICATION object:messageArray userInfo:nil];
    }
}

+ (void)getLatestMessageForUser:(NSString *)deviceKeyString withCompletion:(void (^)( NSMutableArray *messages, NSError *))completion {
    [self getLatestMessageForUser:deviceKeyString withDelegate:nil withCompletion:^(NSMutableArray *messages, NSError *error) {
        completion(messages,error);
    }];
}

+ (BOOL)incrementContactUnreadCount:(ALMessage *)message {

    if (![ALMessageService isIncrementRequired:message]) {
        return NO;
    }

    if (message.groupId != nil) {
        NSNumber *groupId = message.groupId;
        ALChannelDBService *channelDBService =[[ALChannelDBService alloc] init];
        ALChannel *channel = [channelDBService loadChannelByKey:groupId];
        if (![message isResetUnreadCountMessage]) {
            channel.unreadCount = [NSNumber numberWithInt:channel.unreadCount.intValue+1];
            [channelDBService updateUnreadCountChannel:message.groupId unreadCount:channel.unreadCount];
        }
    } else {
        NSString *contactId = message.contactIds;
        ALContactService *contactService = [[ALContactService alloc] init];
        ALContact *contact = [contactService loadContactByKey:@"userId" value:contactId];
        contact.unreadCount = [NSNumber numberWithInt:[contact.unreadCount intValue] + 1];
        [contactService addContact:contact];
    }

    if (message.conversationId != nil) {
        ALConversationService *conversationService = [[ALConversationService alloc] init];
        [conversationService fetchTopicDetails:message.conversationId withCompletion:^(NSError *error, ALConversationProxy *conversationProxy) {
        }];
    }
    return YES;
}

+ (BOOL)resetUnreadCountAndUpdate:(ALMessage *)message {

    if ([message isResetUnreadCountMessage]) {
        ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
        [channelDBService updateUnreadCountChannel:message.groupId unreadCount:[NSNumber numberWithInt:0]];
        return YES;
    }
    return NO;
}

+ (BOOL)isIncrementRequired:(ALMessage *)message {

    if ([message.status isEqualToNumber:[NSNumber numberWithInt:DELIVERED_AND_READ]]
        || (message.groupId && message.contentType == ALMESSAGE_CHANNEL_NOTIFICATION)
        || [message.type isEqualToString:@"5"]
        || [message isHiddenMessage]
        || [message isVOIPNotificationMessage]
        || [message.status isEqualToNumber:[NSNumber numberWithInt:READ]]) {
        return NO;
    } else {
        return YES;
    }
}


+ (void)updateDeliveredReport:(NSArray *)deliveredMessageKeys withStatus:(int)status {
    for (id key in deliveredMessageKeys) {
        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        [messageDBService updateMessageDeliveryReport:key withStatus:status];
    }
}

#pragma mark - Delete message

- (void)deleteMessage:(NSString *)keyString andContactId:(NSString *)contactId withCompletion:(void (^)(NSString *response, NSError *error))completion {

    if (keyString.length == 0) {
        NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                     code:1
                                                 userInfo:@{NSLocalizedDescriptionKey : @"Message key is empty"}];
        completion(nil, responseError);
        return;
    }

    //db
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    DB_Message *dbMessage = (DB_Message *)[messageDBService getMessageByKey:@"key" value:keyString];
    [dbMessage setDeletedFlag:[NSNumber numberWithBool:YES]];
    ALMessage *message = [messageDBService createMessageEntity:dbMessage];
    bool isUsedForReply = (message.getReplyType == AL_A_REPLY);

    if (isUsedForReply) {
        dbMessage.replyMessageType = [NSNumber numberWithInt:AL_REPLY_BUT_HIDDEN];
    }

    NSError *error = [databaseHandler saveContext];
    if (error) {
        ALSLog(ALLoggerSeverityInfo, @"Delete Flag Not Set");
        completion(nil, error);
        return;
    }

    ALSLog(ALLoggerSeverityInfo, @"Deleting message for key: %@",keyString);

    [self.messageClientService deleteMessage:keyString andContactId:contactId
                              withCompletion:^(NSString *response, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        [ALVerification verify:response != nil withErrorMessage:@"Failed to delete the single message response is nil"];

        if (!response) {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to delete the message response is nil"}];

            completion(nil, responseError);
            return;
        }

        NSError *deleteError = nil;
        //none error then delete from DB.
        if (!isUsedForReply) {
            deleteError = [messageDBService deleteMessageByKey:keyString];
        }

        if (deleteError) {
            completion(nil, deleteError);
            return;
        }
        completion(response, nil);

    }];

}

#pragma mark - Delete message thread

- (void)deleteMessageThread:(NSString *)contactId orChannelKey:(NSNumber *)channelKey withCompletion:(void (^)(NSString *response, NSError *error))completion {

    if (!contactId && !channelKey) {
        NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                     code:1
                                                 userInfo:@{NSLocalizedDescriptionKey : @"UserId and channelKey is nil"}];
        completion(nil, responseError);
        return;
    }

    [self.messageClientService deleteMessageThread:contactId orChannelKey:channelKey withCompletion:^(NSString *response, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        [ALVerification verify:response != nil withErrorMessage:@"Failed to delete the message thread response is nil"];

        if (!response) {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to delete the message thread response is nil"}];

            completion(nil, responseError);
            return;
        }

        //delete sucessfull
        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        NSError *deleteThreadError = [messageDBService deleteAllMessagesByContact:contactId orChannelKey:channelKey];
        if (deleteThreadError) {
            completion(nil, deleteThreadError);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Sucessfully deleted the message thread");
        completion(response, error);
    }];
}

+ (ALMessage *)processFileUploadSucess:(ALMessage *)message {

    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    DB_Message *dbMessage = (DB_Message *)[messageDBService getMessageByKey:@"key" value:message.key];

    dbMessage.fileMetaInfo.blobKeyString = message.fileMeta.blobKey;
    dbMessage.fileMetaInfo.thumbnailBlobKeyString = message.fileMeta.thumbnailBlobKey;
    dbMessage.fileMetaInfo.contentType = message.fileMeta.contentType;
    dbMessage.fileMetaInfo.createdAtTime = message.fileMeta.createdAtTime;
    dbMessage.fileMetaInfo.key = message.fileMeta.key;
    dbMessage.fileMetaInfo.name = message.fileMeta.name;
    dbMessage.fileMetaInfo.size = message.fileMeta.size;
    dbMessage.fileMetaInfo.suUserKeyString = message.fileMeta.userKey;
    dbMessage.fileMetaInfo.thumbnailUrl = message.fileMeta.thumbnailUrl;

    message.fileMetaKey = message.fileMeta.key;
    message.msgDBObjectId = [dbMessage objectID];

    NSError *error = [[ALDBHandler sharedInstance] saveContext];
    if (error) {
        ALSLog(ALLoggerSeverityError, @"Failed to save the file meta in db %@",error);
        return nil;
    }
    return message;
}

- (void)processPendingMessages {
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    ALContactDBService *contactDBService = [[ALContactDBService alloc] init];

    NSMutableArray *pendingMessageArray = [messageDBService getPendingMessages];
    ALSLog(ALLoggerSeverityInfo, @"Found pending messages: %lu",(unsigned long)pendingMessageArray.count);

    for (ALMessage *message in pendingMessageArray) {

        if ((!message.fileMeta && !message.pairedMessageKey)) {
            ALSLog(ALLoggerSeverityInfo, @"RESENDING_MESSAGE : %@", message.message);
            [[ALMessageService sharedInstance] sendMessages:message withCompletion:^(NSString *response, NSError *error) {
                if (error) {
                    ALSLog(ALLoggerSeverityError, @"PENDING_MESSAGES_NO_SENT : %@", error);
                    return;
                }

                if (message.groupId == nil) {
                    ALContact *contact = [contactDBService loadContactByKey:@"userId" value:message.to];
                    if (contact && [contact isDisplayNameUpdateRequired]) {
                        [[ALUserService sharedInstance] updateDisplayNameWith:message.to withDisplayName:contact.displayName withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
                            if (apiResponse && [apiResponse.status isEqualToString:AL_RESPONSE_SUCCESS]) {
                                [contactDBService addOrUpdateMetadataWithUserId:message.to withMetadataKey:AL_DISPLAY_NAME_UPDATED withMetadataValue:@"true"];
                            }
                        }];
                    }
                }

                [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:message];
            }];
        } else if (message.contentType == ALMESSAGE_CONTENT_VCARD) {
            DB_Message *dbMessage = (DB_Message *)[messageDBService getMessageByKey:@"key" value:message.key];
            dbMessage.inProgress = [NSNumber numberWithBool:YES];
            dbMessage.isUploadFailed = [NSNumber numberWithBool:NO];

            NSError *error = [[ALDBHandler sharedInstance] saveContext];

            if (error) {
                NSLog(@"Failed to save the flags for message error %@",error);
                continue;
            }

            ALHTTPManager *httpManager = [[ALHTTPManager alloc] init];
            httpManager.attachmentProgressDelegate = self;

            NSDictionary *messageDictionary = [message dictionary];
            [self.messageClientService sendPhotoForUserInfo:messageDictionary withCompletion:^(NSString *responseUrl, NSError *error) {

                if (!error) {
                    [httpManager processUploadFileForMessage:[messageDBService createMessageEntity:dbMessage] uploadURL:responseUrl];
                }
            }];
        } else {
            ALSLog(ALLoggerSeverityInfo, @"FILE_META_PRESENT : %@",message.fileMeta );
        }
    }
}

#pragma mark - Sync latest messages

+ (void)syncMessages {
    if ([ALUserDefaultsHandler isLoggedIn]) {
        [ALMessageService getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString] withCompletion:^(NSMutableArray *messageArray, NSError *error) {

            if (error) {
                ALSLog(ALLoggerSeverityError, @"Error in fetching latest sync messages : %@",error);
            }
        }];
    }
}

+ (ALMessage*)getMessagefromKeyValuePair:(NSString *)key andValue:(NSString *)value {
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    DB_Message *dbMessage = (DB_Message *)[messageDBService getMessageByKey:key value:value];
    return [messageDBService createMessageEntity:dbMessage];
}

#pragma mark - Message information with message key

- (void)getMessageInformationWithMessageKey:(NSString *)messageKey
                      withCompletionHandler:(void(^)(ALMessageInfoResponse *messageInfoResponse, NSError *error))completion {

    if (messageKey.length == 0) {
        NSError *messageKeyError = [NSError errorWithDomain:@"Applozic"
                                                       code:MessageNotPresent
                                                   userInfo:@{NSLocalizedDescriptionKey : @"Message key passed is empty"}];
        completion(nil, messageKeyError);
        return;
    }

    [self.messageClientService getCurrentMessageInformation:messageKey
                                      withCompletionHandler:^(ALMessageInfoResponse *messageInfoResponse, NSError *error) {

        completion(messageInfoResponse, error);
    }];
}

#pragma mark - Sent message sync with delegate

+ (void)getMessageSENT:(ALMessage *)message
          withDelegate:(id<ApplozicUpdatesDelegate>)delegate
        withCompletion:(void (^)( NSMutableArray *, NSError *))completion {

    ALMessage *localMessage = [ALMessageService getMessagefromKeyValuePair:@"key" andValue:message.key];
    if (localMessage.key == nil) {
        [self getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString]
                         withDelegate:delegate
                       withCompletion:^(NSMutableArray *messageArray, NSError *error) {
            completion(messageArray, error);
        }];
    }
}

#pragma mark - Sent message sync

+ (void)getMessageSENT:(ALMessage *)message withCompletion:(void (^)( NSMutableArray *messageArray, NSError *error))completion {

    [self getMessageSENT:message withDelegate:nil withCompletion:^(NSMutableArray *messageArray, NSError *error) {
        completion(messageArray, error);
    }];
}

#pragma mark - Multi Receiver API

+ (void)multiUserSendMessage:(ALMessage *)message
                  toContacts:(NSMutableArray *)contactIdsArray
                    toGroups:(NSMutableArray *)channelKeysArray
              withCompletion:(void(^)(NSString *jsonResponse, NSError *error)) completion {
    ALUserClientService *userClientService = [[ALUserClientService alloc] init];
    [userClientService multiUserSendMessage:[message dictionary]
                                 toContacts:contactIdsArray
                                   toGroups:channelKeysArray
                             withCompletion:^(NSString *jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"SERVICE_ERROR: Multi User Send Message : %@", error);
        }
        completion(jsonResponse, error);
    }];
}

+ (ALMessage *)createCustomTextMessageEntitySendTo:(NSString *)to withText:(NSString *)text {
    return [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_CUSTOM toSendTo:to withText:text];
}

+ (ALMessage *)createHiddenMessageEntitySentTo:(NSString *)to withText:(NSString *)text {
    return [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_HIDDEN toSendTo:to withText:text];
}

+ (ALMessage *)createMessageEntityOfContentType:(int)contentType
                                       toSendTo:(NSString *)to
                                       withText:(NSString *)text {

    ALMessage *message = [ALMessage new];

    message.contactIds = to;//1
    message.to = to;//2
    message.message = text;//3
    message.contentType = contentType;//4

    message.type = @"5";
    message.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
    message.deviceKey = [ALUserDefaultsHandler getDeviceKeyString ];
    message.sendToDevice = NO;
    message.shared = NO;
    message.fileMeta = nil;
    message.storeOnDevice = NO;
    message.key = [[NSUUID UUID] UUIDString];
    message.delivered = NO;
    message.fileMetaKey = nil;

    return message;
}

+ (ALMessage *)createMessageWithMetaData:(NSMutableDictionary *)metaData
                          andContentType:(short)contentType
                           andReceiverId:(NSString *)receiverId
                          andMessageText:(NSString *)msgTxt {
    ALMessage *message = [self createMessageEntityOfContentType:contentType toSendTo:receiverId withText:msgTxt];

    message.metadata = metaData;
    return message;
}

- (NSUInteger)getMessagsCountForUser:(NSString *)userId {
    ALMessageDBService *messageDBService = [ALMessageDBService new];
    return [messageDBService getMessagesCountFromDBForUser:userId];
}

#pragma mark Get latest message for User/Channel

- (ALMessage *)getLatestMessageForUser:(NSString *)userId {
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    return [messageDBService getLatestMessageForUser:userId];
}

- (ALMessage *)getLatestMessageForChannel:(NSNumber *)channelKey excludeChannelOperations:(BOOL)flag {
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    return [messageDBService getLatestMessageForChannel:channelKey excludeChannelOperations:flag];
}

- (ALMessage *)getALMessageByKey:(NSString *)messageReplyId {
    //GET Message From Server if not present on Server
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    DB_Message *dbMessage = (DB_Message *)[messageDBService getMessageByKey:@"key" value:messageReplyId];
    return [messageDBService createMessageEntity:dbMessage];
}

+ (void)addOpenGroupMessage:(ALMessage *)message
               withDelegate:(id<ApplozicUpdatesDelegate>)delegate
             withCompletion:(void (^)(BOOL success))completion {

    if (!message) {
        completion(NO);
        return;
    }

    NSMutableArray *singleMessageArray = [[NSMutableArray alloc] init];
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    ALContactService *contactService = [ALContactService new];
    NSMutableArray *userNotPresentIds = [NSMutableArray new];
    [singleMessageArray addObject:message];

    BOOL syncChannel = NO;

    for (int i=0; i<singleMessageArray.count; i++) {
        ALMessage *message = singleMessageArray[i];
        if (message.groupId != nil && message.contentType == ALMESSAGE_CHANNEL_NOTIFICATION) {
            syncChannel = YES;
            if ([message isMsgHidden]) {
                [singleMessageArray removeObjectAtIndex:i];
            }
        }

        NSMutableArray<NSString *>* replyMessageKeys = [[NSMutableArray alloc] init];
        if (message.metadata) {
            NSString *replyKey = [message.metadata valueForKey:AL_MESSAGE_REPLY_KEY];
            if (replyKey && ![messageDBService getMessageByKey:@"key" value: replyKey] && ![replyMessageKeys containsObject: replyKey]) {
                [replyMessageKeys addObject: replyKey];
            }
        }

        [[ALMessageService sharedInstance] fetchReplyMessages:replyMessageKeys withCompletion:^(NSMutableArray<ALMessage *> *replyMessages) {
            if (replyMessages && replyMessages.count > 0) {
                for (int i = 0; i < replyMessages.count; i++) {
                    if (![contactService isContactExist:replyMessages[i].to]) {
                        [userNotPresentIds addObject: replyMessages[i].to];
                    }
                }
            }
            if (userNotPresentIds.count > 0) {
                ALUserService *userService = [ALUserService new];
                [userService getUserDetails:userNotPresentIds withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                    if (!error) {
                        [self processMessage:message
                             withSkipMessage:YES
                                withDelegate:delegate
                                 syncChannel:syncChannel
                              withCompletion:^(BOOL success) {
                            completion(success);
                        }];
                    } else {
                        completion(NO);
                    }
                }];
            } else {
                [self processMessage:message
                     withSkipMessage:YES
                        withDelegate:delegate
                         syncChannel:syncChannel
                      withCompletion:^(BOOL success) {

                    completion(success);
                }];
            }
        }];
    }
}

+(void)processMessage:(ALMessage *)message
      withSkipMessage:(BOOL)skip
         withDelegate:(id<ApplozicUpdatesDelegate>)delegate
          syncChannel:(BOOL)syncChannel
       withCompletion:(void (^)(BOOL success))completion {
    if (syncChannel) {
        ALChannelService *channelService = [[ALChannelService alloc] init];
        [channelService syncCallForChannelWithDelegate:delegate
                                        withCompletion:^(ALChannelSyncResponse *response, NSError *error) {
            [self saveAndPostMessage:message withSkipMessage:YES withDelegate:delegate];
            completion(YES);
        }];
    } else {
        [self saveAndPostMessage:message withSkipMessage:YES withDelegate:delegate];
        completion(YES);
    }
}

+(void)saveAndPostMessage:(ALMessage *)message
          withSkipMessage:(BOOL)skip
             withDelegate:(id<ApplozicUpdatesDelegate>)delegate {

    if (message) {
        NSMutableArray *messageArray = [[NSMutableArray alloc] init];
        [messageArray addObject:message];

        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        [messageDBService addMessageList:messageArray skipAddingMessageInDb:skip];

        if (delegate) {
            if ([message.type isEqual: AL_OUT_BOX]) {
                [delegate onMessageSent: message];
            } else {
                [delegate onMessageReceived: message];
            }
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_MESSAGE_NOTIFICATION object:messageArray userInfo:nil];
    }
}

#pragma mark - Message list for one to one or Channel/Group

- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler:(void(^)(NSMutableArray *messageList, NSError *error)) completion {

    ALMessageDBService *messageDbService = [[ALMessageDBService alloc] init];

    [messageDbService getLatestMessages:isNextPage withOnlyGroups:isGroup withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
        completion(messageList, error);
    }];
}

- (ALMessage *)handleMessageFailedStatus:(ALMessage *)message {
    ALMessageDBService *messageDBServce = [[ALMessageDBService alloc] init];
    return [messageDBServce handleMessageFailedStatus:message];
}

#pragma mark - Get Message by key

- (ALMessage *)getMessageByKey:(NSString *)messageKey {
    if (!messageKey) {
        return nil;
    }

    ALMessageDBService *messageDBServce = [[ALMessageDBService alloc] init];
    return [messageDBServce getMessageByKey:messageKey];
}

#pragma mark - Sync message metadata

+ (void)syncMessageMetaData:(NSString *)deviceKeyString
             withCompletion:(void (^)( NSMutableArray *messageArray, NSError *error))completion {
    if (!alMsgClientService) {
        alMsgClientService = [[ALMessageClientService alloc] init];
    }
    @synchronized(alMsgClientService) {
        [alMsgClientService getLatestMessageForUser:deviceKeyString withMetaDataSync:YES withCompletion:^(ALSyncMessageFeed *syncMessageFeed, NSError *error) {
            NSMutableArray *messageArray = nil;

            if (!error) {
                if (syncMessageFeed.messagesList.count > 0) {
                    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
                    for (ALMessage *message in syncMessageFeed.messagesList) {
                        [messageDBService updateMessageMetadataOfKey:message.key withMetadata:message.metadata];
                        [[NSNotificationCenter defaultCenter] postNotificationName:AL_MESSAGE_META_DATA_UPDATE object:message userInfo:nil];
                    }
                }
                [ALUserDefaultsHandler setLastSyncTimeForMetaData:syncMessageFeed.lastSyncTime];
                completion(syncMessageFeed.messagesList, error);
            } else {
                completion(messageArray, error);
            }
        }];
    }
}

#pragma mark - Update message metadata

- (void)updateMessageMetadataOfKey:(NSString *)messageKey
                      withMetadata:(NSMutableDictionary *)metadata
                    withCompletion:(void (^)(ALAPIResponse *, NSError *))completion {

    if (messageKey.length == 0 || !metadata) {
        NSError *messageKeyError = [NSError errorWithDomain:@"Applozic"
                                                       code:MessageNotPresent
                                                   userInfo:@{NSLocalizedDescriptionKey : @"Message key or meta data passed is nil"}];
        
        completion(nil, messageKeyError);
        return;
    }

    [self.messageClientService updateMessageMetadataOfKey:messageKey withMetadata:metadata withCompletion:^(id jsonResponse, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];

        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

            NSString *errorMessage = [response.errorResponse errorDescriptionMessage];

            NSError *updateMetadataError = [NSError errorWithDomain:@"Applozic" code:1
                                                           userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"Failed to update message meta data due to api error.": errorMessage

                                                                                                forKey:NSLocalizedDescriptionKey]];

            completion(nil, updateMetadataError);
            return;
        }
        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        [messageDBService updateMessageMetadataOfKey:messageKey withMetadata:metadata];
        completion(response, nil);
    }];
}

#pragma mark - Fetch reply message

- (void)fetchReplyMessages:(NSMutableArray<NSString *> *)keys withCompletion:(void(^)(NSMutableArray<ALMessage *>* messages))completion {
    if (!keys || keys.count < 1) {
        completion(nil);
        return;
    }
    [self.messageClientService getMessagesWithkeys:keys withCompletion:^(ALAPIResponse *response, NSError *error) {
        if (error || [response.status isEqualToString:AL_RESPONSE_ERROR]) {
            completion(nil);
            return;
        }
        NSDictionary *messageDictionary = [response.response valueForKey:@"message"];
        NSMutableArray<ALMessage *> *messageList = [[NSMutableArray alloc] init];
        for (NSDictionary *msgDictionary  in messageDictionary) {
            ALMessage *message = [[ALMessage alloc] initWithDictonary: msgDictionary];
            message.messageReplyType = [NSNumber numberWithInt:AL_REPLY_BUT_HIDDEN];
            [[[ALMessageDBService alloc] init] addMessage: message];
            [messageList addObject:message];
        }
        completion(messageList);
    }];
}

- (void)onDownloadCompleted:(ALMessage *)message {

}

- (void)onDownloadFailed:(ALMessage *)message {

}

- (void)onUpdateBytesDownloaded:(int64_t)bytesReceived withMessage:(ALMessage *)message {

}

- (void)onUpdateBytesUploaded:(int64_t)bytesSent withMessage:(ALMessage *)message {

}

- (void)onUploadCompleted:(ALMessage *)updatedMessage withOldMessageKey:(NSString *)oldMessageKey {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:updatedMessage];
    ALContactDBService *contactDBService = [[ALContactDBService alloc] init];
    if (updatedMessage.groupId == nil) {
        ALContact *contact = [contactDBService loadContactByKey:@"userId" value:updatedMessage.to];
        if (contact && [contact isDisplayNameUpdateRequired] ) {
            [[ALUserService sharedInstance] updateDisplayNameWith:updatedMessage.to withDisplayName:contact.displayName withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
                if (apiResponse && [apiResponse.status isEqualToString:AL_RESPONSE_SUCCESS]) {
                    [contactDBService addOrUpdateMetadataWithUserId:updatedMessage.to withMetadataKey:AL_DISPLAY_NAME_UPDATED withMetadataValue:@"true"];
                }
            }];
        }
    }
}

- (void)onUploadFailed:(ALMessage *)message {

}

#pragma mark - Delete message for all

- (void)deleteMessageForAllWithKey:(NSString *)keyString
                    withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {
    if (keyString.length == 0) {
        NSError *messageKeyNilError = [NSError errorWithDomain:@"Applozic"
                                                          code:1
                                                      userInfo:@{NSLocalizedDescriptionKey : @"Passed message key is nil"}];
        completion(nil, messageKeyNilError);
        return;
    }

    [self.messageClientService deleteMessageForAllWithKey:keyString withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {

        completion(apiResponse, error);
    }];
}

#pragma mark - Total unread message count

- (void)getTotalUnreadMessageCountWithCompletionHandler:(void (^)(NSUInteger unreadCount, NSError *error))completion {
    ALUserService *userService = [[ALUserService alloc] init];
    if (![ALUserDefaultsHandler isInitialMessageListCallDone]) {
        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        [messageDBService getLatestMessages:NO
                      withCompletionHandler:^(NSMutableArray *messages, NSError *error) {
            if (error) {
                completion(0, error);
                return;
            }
            NSNumber *totalUnreadCount = [userService getTotalUnreadCount];
            completion(totalUnreadCount.integerValue, nil);
        }];
    } else {
        NSNumber *totalUnreadCount = [userService getTotalUnreadCount];
        completion(totalUnreadCount.integerValue, nil);
    }
}

#pragma mark - Total unread conversation count

- (void)getTotalUnreadConversationCountWithCompletionHandler:(void (^)(NSUInteger conversationUnreadCount, NSError *error))completion {
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    [messageDBService getLatestMessages:NO withCompletionHandler:^(NSMutableArray *messages, NSError *error) {

        if (error) {
            completion(0, error);
            return;
        }
        NSUInteger unreadCount = 0;

        ALChannelService *channelService = [[ALChannelService alloc] init];
        ALContactDBService *contactDBService = [[ALContactDBService alloc] init];
        
        for (ALMessage *message in messages) {
            if (message.groupId &&
                message.groupId.integerValue != 0) {
                ALChannel *channel = [channelService getChannelByKey:message.groupId];
                if (channel && channel.unreadCount.integerValue > 0) {
                    unreadCount += 1;
                }
            } else {
                ALContact *contact = [contactDBService loadContactByKey:@"userId" value:message.to];
                if (contact && contact.unreadCount.integerValue > 0) {
                    unreadCount += 1;
                }
            }
        }
        completion(unreadCount, nil);
    }];
}

@end
