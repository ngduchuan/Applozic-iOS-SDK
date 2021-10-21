//
//  ALMessageDBService.m
//  ChatApp
//
//  Created by Devashish on 21/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALApplozicSettings.h"
#import "ALChannel.h"
#import "ALChannelService.h"
#import "ALContact.h"
#import "ALContactService.h"
#import "ALDBHandler.h"
#import "ALLogger.h"
#import "ALMessage.h"
#import "ALMessageClientService.h"
#import "ALMessageDBService.h"
#import "ALMessageService.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserService.h"
#import "ALUtilityClass.h"
#import "DB_FileMetaInfo.h"
#import "DB_Message.h"

@implementation ALMessageDBService

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
    self.messageService = [[ALMessageService alloc] init];
}

- (NSMutableArray *)addMessageList:(NSMutableArray *)messages
             skipAddingMessageInDb:(BOOL)skip {
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    for (ALMessage *message in messages) {
        
        if (skip && !message.fileMeta) {
            [messageArray addObject:message];
            continue;
        }
        
        NSManagedObject *managedObjectMessage = [self getMessageByKey:@"key" value:message.key];
        if (managedObjectMessage == nil && ![message isPushNotificationMessage]) {
            message.sentToServer = YES;
            
            DB_Message *dbMessageEntity = [self createMessageEntityForDBInsertionWithMessage:message];
            
            if (dbMessageEntity) {
                message.msgDBObjectId = dbMessageEntity.objectID;
                [messageArray addObject:message];
            }
            
        } else if (managedObjectMessage != nil) {
            DB_Message *dbMessage = (DB_Message *)managedObjectMessage;
            if (dbMessage && [dbMessage.replyMessageType intValue] == AL_REPLY_BUT_HIDDEN) {
                int replyType = (dbMessage.metadata && [dbMessage.metadata containsString:AL_MESSAGE_REPLY_KEY]) ? AL_A_REPLY : AL_NOT_A_REPLY;
                [self updateMessageReplyType:dbMessage.key replyType: [NSNumber numberWithInt:replyType] hideFlag:NO];
            }
        }
    }
    
    NSError *error = [databaseHandler saveContext];
    if (error) {
        ALSLog(ALLoggerSeverityError, @"Unable to save Messages in addMessageList error :%@",error);
    }
    
    return messageArray;
}

#pragma mark - Add message in Database

- (DB_Message *)addMessage:(ALMessage *)message {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    DB_Message *dbMessage = [self createMessageEntityForDBInsertionWithMessage:message];
    
    if (dbMessage) {
        NSError *error = [databaseHandler saveContext];
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Failed to save the message :%@",error);
            return nil;
        }
        
        message.msgDBObjectId = dbMessage.objectID;
        if ([message.status isEqualToNumber:[NSNumber numberWithInt:SENT]]) {
            dbMessage.status = [NSNumber numberWithInt:READ];
        }
        if (message.isAReplyMessage) {
            NSString *messageReplyId = [message.metadata valueForKey:AL_MESSAGE_REPLY_KEY];
            DB_Message *replyMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageReplyId];
            if (replyMessage) {
                replyMessage.replyMessageType = [NSNumber numberWithInt:AL_A_REPLY];
                NSError *error = [databaseHandler saveContext];
                if (error) {
                    ALSLog(ALLoggerSeverityError, @"Failed to update the reply type in the message :%@",error);
                }
            }
        }
    }
    
    return dbMessage;
}

- (NSManagedObject *)getMeesageById:(NSManagedObjectID *)objectID {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSManagedObject *messageManagedObject = [databaseHandler existingObjectWithID:objectID];
    return messageManagedObject;
}

- (void)updateDeliveryReportForContact:(NSString *)contactId
                            withStatus:(int)status {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *dbMessasgeEntity = [databaseHandler entityDescriptionWithEntityForName:@"DB_Message"];
    
    if (dbMessasgeEntity) {
        
        NSMutableArray *predicateArray = [[NSMutableArray alloc] init];
        
        NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@",contactId];
        [predicateArray addObject:predicate1];
        
        NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"status != %i and sentToServer ==%@",
                                   DELIVERED_AND_READ,[NSNumber numberWithBool:YES]];
        [predicateArray addObject:predicate3];
        
        NSCompoundPredicate *resultantPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
        
        [fetchRequest setEntity:dbMessasgeEntity];
        [fetchRequest setPredicate:resultantPredicate];
        NSError *fetchError = nil;
        NSArray *result = [databaseHandler executeFetchRequest:fetchRequest withError:&fetchError];
        
        if (result.count > 0) {
            ALSLog(ALLoggerSeverityInfo, @"Found Messages to update to DELIVERED_AND_READ in DB :%lu",(unsigned long)result.count);
            for (DB_Message *dbMessage in result) {
                [dbMessage setStatus:[NSNumber numberWithInt:status]];
            }
            
            NSError *error = [databaseHandler saveContext];
            
            if (error) {
                ALSLog(ALLoggerSeverityError, @"Unable to save STATUS OF managed objects. %@, %@", error, error.localizedDescription);
            }
        }
    }
}

#pragma mark - Update message Delivery report in Database

- (void)updateMessageDeliveryReport:(NSString *)messageKeyString
                         withStatus:(int)status {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    
    NSManagedObject *dbMessage = [self getMessageByKey:@"key" value:messageKeyString];
    
    if (dbMessage) {
        [dbMessage setValue:@(status) forKey:@"status"];
        NSError *error = [databaseHandler saveContext];
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in updating Message Delivery Report %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"Update message delivery report in DB update Success %@", messageKeyString);
        }
    }
}

- (void)updateMessageSyncStatus:(NSString *)keyString {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSManagedObject *dbMessage = [self getMessageByKey:@"keyString" value:keyString];
    if (dbMessage) {
        [dbMessage setValue:@"1" forKey:@"isSent"];
        NSError *error = [databaseHandler saveContext];
        
        if (error) {
            ALSLog(ALLoggerSeverityInfo, @"Message deliverd status updated Failed  %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"Message found and maked as deliverd");
        }
    }
}

#pragma mark - Delete message by messagekey

- (void)deleteMessageByKey:(NSString *)keyString {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSManagedObject *message = [self getMessageByKey:@"key" value:keyString];
    
    if (message) {
        [databaseHandler deleteObject:message];
        NSError *error = [databaseHandler saveContext];
        if (error) {
            ALSLog(ALLoggerSeverityInfo, @"Failed to delete the message got some error: %@", error);
        }
    } else {
        ALSLog(ALLoggerSeverityInfo, @"Failed to delete the Message not found with this key: %@", keyString);
    }
}

#pragma mark - Delete all messages for user or group

- (void)deleteAllMessagesByContact:(NSString *)contactId
                      orChannelKey:(NSNumber *)key {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *dbMessageEntity = [databaseHandler entityDescriptionWithEntityForName:@"DB_Message"];
    
    if (dbMessageEntity) {
        NSPredicate *predicate;
        if (key != nil) {
            predicate = [NSPredicate predicateWithFormat:@"groupId = %@",key];
            ALChannelService *channelService = [[ALChannelService alloc] init];
            [channelService setUnreadCountZeroForGroupID:key];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"contactId = %@ AND groupId = %@",contactId,nil];
            ALUserService *userService = [[ALUserService alloc] init];
            [userService setUnreadCountZeroForContactId:contactId];
        }
        
        [fetchRequest setEntity:dbMessageEntity];
        [fetchRequest setPredicate:predicate];
        
        NSError *fetchError = nil;
        NSArray *result =  [databaseHandler executeFetchRequest:fetchRequest withError:&fetchError];
        
        if (result.count > 0) {
            
            for (DB_Message *message in result) {
                [databaseHandler deleteObject:message];
            }
            
            NSError *deleteError = [databaseHandler saveContext];
            
            if (deleteError) {
                ALSLog(ALLoggerSeverityError, @"Unable to save managed object context %@, %@", deleteError, deleteError.localizedDescription);
            }
        }
    }
}

#pragma mark - Message table is empty

- (BOOL)isMessageTableEmpty {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSEntityDescription *dbMessageEntity = [databaseHandler entityDescriptionWithEntityForName:@"DB_Message"];
    if (dbMessageEntity) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:dbMessageEntity];
        [fetchRequest setIncludesPropertyValues:NO];
        [fetchRequest setIncludesSubentities:NO];
        NSUInteger count = [databaseHandler countForFetchRequest:fetchRequest];
        return !(count >0);
    }
    return true;
}

#pragma mark - Delete all objects in Database tables

- (void)deleteAllObjectsInCoreData {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSArray *allEntities = databaseHandler.managedObjectModel.entities;
    if (allEntities.count) {
        for (NSEntityDescription *entityDescription in allEntities) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:entityDescription];
            
            fetchRequest.includesPropertyValues = NO;
            fetchRequest.includesSubentities = NO;
            NSError *fetchError = nil;
            NSArray *result = [databaseHandler executeFetchRequest:fetchRequest withError:&fetchError];
            
            if (fetchError) {
                ALSLog(ALLoggerSeverityError, @"Error requesting items from Core Data: %@", [fetchError localizedDescription]);
                return;
            }
            
            for (NSManagedObject *managedObject in result) {
                [databaseHandler deleteObject:managedObject];
            }
            
            NSError *saveError = [databaseHandler saveContext];
            if (saveError) {
                ALSLog(ALLoggerSeverityError, @"Error deleting %@ - error:%@", saveError, [saveError localizedDescription]);
            }
        }
    }
}

#pragma mark - Get Database message by message key

- (NSManagedObject *)getMessageByKey:(NSString *)key value:(NSString *)value {
    
    //Runs at MessageList viewing/opening...ONLY FIRST TIME AND if delete an msg
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *dbMessageEntity = [databaseHandler entityDescriptionWithEntityForName:@"DB_Message"];
    if (dbMessageEntity) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@",key,value];
        NSPredicate *resultPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate]];
        [fetchRequest setEntity:dbMessageEntity];
        [fetchRequest setPredicate:resultPredicate];
        NSError *fetchError = nil;
        NSArray *result = [databaseHandler executeFetchRequest:fetchRequest withError:&fetchError];
        if (result.count > 0) {
            NSManagedObject* message = [result objectAtIndex:0];
            return message;
        }
    }
    return nil;
}

#pragma mark - ALMessagesViewController DB Operations.

- (void)getMessages:(NSMutableArray *)subGroupList {
    if ([self isMessageTableEmpty] ||
        [ALApplozicSettings getCategoryName] ||
        ![ALUserDefaultsHandler isInitialMessageListCallDone]) {
        [self fetchAndRefreshFromServer:subGroupList];
    } else  {
        /// Db is synced
        /// Fetch data from db
        if (subGroupList && [ALApplozicSettings getSubGroupLaunchFlag]) {
            /// case for sub group
            [self fetchSubGroupConversations:subGroupList];
        } else {
            [self fetchConversationsGroupByContactId];
        }
    }
}

- (void)fetchAndRefreshFromServer:(NSMutableArray *)subGroupList {
    [self syncConverstionDBWithCompletion:^(BOOL success, NSMutableArray *messages) {
        
        if (success) {
            /// save data into the db
            [self addMessageList:messages skipAddingMessageInDb:NO];
            /// set yes to userdefaults
            [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
            /// add default contacts
            /// fetch data from db
            if (subGroupList && [ALApplozicSettings getSubGroupLaunchFlag]) {
                [self fetchSubGroupConversations:subGroupList];
            } else {
                [self fetchConversationsGroupByContactId];
            }
        }
    }];
}

- (void)fetchAndRefreshQuickConversationWithCompletion:(void (^)( NSMutableArray *messages, NSError *error))completion {
    NSString *deviceKeyString = [ALUserDefaultsHandler getDeviceKeyString];
    
    [ALMessageService getLatestMessageForUser:deviceKeyString withCompletion:^(NSMutableArray *messages, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Failed to fetch the latest messages for user with error: %@",error);
            completion (nil, error);
            return;
        }
        [self.delegate updateMessageList:messages];
        
        completion (messages, error);
    }];
    
}

#pragma mark - Helper methods

- (void)syncConverstionDBWithCompletion:(void(^)(BOOL success, NSMutableArray *messages)) completion {
    
    [self.messageService getMessagesListGroupByContactswithCompletionService:^(NSMutableArray *messages, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Failed to fetch the list of messages group by contacts with error: %@",error);
            completion(NO, nil);
            return;
        }
        completion(YES, messages);
    }];
}

- (void)getLatestMessagesWithCompletion:(void(^)(NSMutableArray *messages, NSError *error)) completion {
    [self.messageService getMessagesListGroupByContactswithCompletionService:^(NSMutableArray *messages, NSError *error) {
        completion(messages, error);
    }];
}

- (NSArray *)getMessageList:(int)messageCount messageTypeOnlyReceived:(BOOL)received {
    
    // Get the latest record
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *messageRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [messageRequest setResultType:NSDictionaryResultType];
    [messageRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    if (received) {
        /// Load messages with type received
        [messageRequest setPredicate:[NSPredicate predicateWithFormat:@"type == %@ AND deletedFlag == %@ AND contentType != %i AND msgHidden == %@",@"4",@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
    } else {
        /// No type restriction
        [messageRequest setPredicate:[NSPredicate predicateWithFormat:@"deletedFlag == %@ AND contentType != %i AND msgHidden == %@",@(NO), ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
    }
    
    NSArray *messageArray = [databaseHandler executeFetchRequest:messageRequest withError:nil];
    /// Trim the message list
    if (messageArray.count > 0) {
        return [messageArray subarrayWithRange:NSMakeRange(0, MIN(messageCount, messageArray.count))];
    }
    
    return nil;
}

- (void)fetchConversationsGroupByContactId {
    [self fetchLatestConversationsGroupByContactId :NO];
}

- (NSMutableArray *)fetchLatestConversationsGroupByContactId:(BOOL)isFetchOnCreatedAtTime {
    
    ALConversationListRequest *conversationListRequest = [[ALConversationListRequest alloc] init];
    
    NSMutableArray *sortedArray = [self fetchLatestMessagesFromDatabaseWithRequestList:conversationListRequest];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(getMessagesArray:)]) {
        [self.delegate getMessagesArray:sortedArray];
    }
    
    return sortedArray;
}

- (NSMutableArray *)fetchLatestMessagesFromDatabaseWithRequestList:(ALConversationListRequest *)conversationListRequest {
    
    NSPredicate *predicateCreatedAt;
    if (conversationListRequest.endTimeStamp
        && conversationListRequest.startTimeStamp == nil) {
        predicateCreatedAt = [NSPredicate predicateWithFormat:@"createdAt < %@",conversationListRequest.endTimeStamp];
    } else if (conversationListRequest.startTimeStamp != nil) {
        predicateCreatedAt = [NSPredicate predicateWithFormat:@"createdAt >= %@",conversationListRequest.startTimeStamp];
    }
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    /// get all unique contacts
    NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [messageFetchRequest setResultType:NSDictionaryResultType];
    [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    if (predicateCreatedAt) {
        [messageFetchRequest setPredicate:predicateCreatedAt];
    }
    
    [messageFetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"groupId", nil]];
    [messageFetchRequest setReturnsDistinctResults:YES];
    
    NSError *fetchError = nil;
    NSArray *dbMessages = [databaseHandler executeFetchRequest:messageFetchRequest withError:&fetchError];
    NSMutableArray *messagesArray = [NSMutableArray new];
    if (dbMessages.count > 0) {
        /// get latest record
        for (NSDictionary *messageDictionary in dbMessages) {
            NSFetchRequest *dbMessageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
            if ([messageDictionary[@"groupId"] intValue]==0) {
                continue;
            }
            if ([ALApplozicSettings getCategoryName]) {
                ALChannel *channel =  [[ALChannelService new] getChannelByKey:[NSNumber numberWithInt:[messageDictionary[@"groupId"] intValue]]];
                if (![channel isPartOfCategory:[ALApplozicSettings getCategoryName]]) {
                    continue;
                }
            }
            [dbMessageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
            [dbMessageFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"groupId==%d AND deletedFlag == %@ AND contentType != %i AND msgHidden == %@",
                                                 [messageDictionary[@"groupId"] intValue],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
            [dbMessageFetchRequest setFetchLimit:1];
            
            NSArray *groupMessageArray = [databaseHandler executeFetchRequest:dbMessageFetchRequest withError:nil];
            if (groupMessageArray.count > 0) {
                DB_Message *dbMessageEntity = groupMessageArray.firstObject;
                if (groupMessageArray.count) {
                    ALMessage *message = [self createMessageEntity:dbMessageEntity];
                    [messagesArray addObject:message];
                }
            }
        }
    }
    /// Find all message only have contact ...
    NSFetchRequest *userMessageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [userMessageFetchRequest setResultType:NSDictionaryResultType];
    NSPredicate *groupRemovePredicate = [NSPredicate predicateWithFormat:@"groupId=%d OR groupId=nil",0];
    
    if (predicateCreatedAt) {
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateCreatedAt, groupRemovePredicate]];
        [userMessageFetchRequest setPredicate:compoundPredicate];
    } else {
        [userMessageFetchRequest setPredicate:groupRemovePredicate];
    }
    
    [userMessageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [userMessageFetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"contactId", nil]];
    [userMessageFetchRequest setReturnsDistinctResults:YES];
    
    NSArray *userMessageArray = [databaseHandler executeFetchRequest:userMessageFetchRequest withError:nil];
    
    if (userMessageArray.count > 0) {
        for (NSDictionary *messageDictionary in userMessageArray) {
            
            NSFetchRequest *dbMessageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
            [dbMessageFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"contactId = %@ and groupId=nil and deletedFlag == %@ AND contentType != %i AND msgHidden == %@",messageDictionary[@"contactId"],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
            
            [dbMessageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
            [dbMessageFetchRequest setFetchLimit:1];
            
            NSArray *fetchArray =  [databaseHandler executeFetchRequest:dbMessageFetchRequest withError:nil];
            if (fetchArray.count > 0) {
                DB_Message *dbMessageEntity = fetchArray.firstObject;
                if (fetchArray.count) {
                    ALMessage *message = [self createMessageEntity:dbMessageEntity];
                    [messagesArray addObject:message];
                }
            }
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:NO];
    NSArray *sortedMessageArray = [NSArray arrayWithObject:sortDescriptor];
    NSMutableArray *sortedArray = [[messagesArray sortedArrayUsingDescriptors:sortedMessageArray] mutableCopy];
    
    return sortedArray;
}

- (DB_Message *)createMessageEntityForDBInsertionWithMessage:(ALMessage *)message {
    
    //Runs at MessageList viewing/opening... ONLY FIRST TIME
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    
    DB_Message *dbMessageEntity = (DB_Message *)[databaseHandler insertNewObjectForEntityForName:@"DB_Message"];
    
    if (dbMessageEntity) {
        dbMessageEntity.contactId = message.contactIds;
        dbMessageEntity.createdAt =  message.createdAtTime;
        dbMessageEntity.deviceKey = message.deviceKey;
        dbMessageEntity.status = [NSNumber numberWithInt:([dbMessageEntity.type isEqualToString:@"5"] ? READ
                                                          : message.status.intValue)];
        
        dbMessageEntity.isSentToDevice = [NSNumber numberWithBool:message.sendToDevice];
        dbMessageEntity.isShared = [NSNumber numberWithBool:message.shared];
        dbMessageEntity.isStoredOnDevice = [NSNumber numberWithBool:message.storeOnDevice];
        dbMessageEntity.key = message.key;
        dbMessageEntity.messageText = message.message;
        dbMessageEntity.userKey = message.userKey;
        dbMessageEntity.to = message.to;
        dbMessageEntity.type = message.type;
        dbMessageEntity.delivered = [NSNumber numberWithBool:message.delivered];
        dbMessageEntity.sentToServer = [NSNumber numberWithBool:message.sentToServer];
        dbMessageEntity.filePath = message.imageFilePath;
        dbMessageEntity.inProgress = [NSNumber numberWithBool:message.inProgress];
        dbMessageEntity.isUploadFailed=[ NSNumber numberWithBool:message.isUploadFailed];
        dbMessageEntity.contentType = message.contentType;
        dbMessageEntity.deletedFlag=[NSNumber numberWithBool:message.deleted];
        dbMessageEntity.conversationId = message.conversationId;
        dbMessageEntity.pairedMessageKey = message.pairedMessageKey;
        dbMessageEntity.metadata = message.metadata.description;
        dbMessageEntity.msgHidden = [NSNumber numberWithBool:[message isHiddenMessage]];
        dbMessageEntity.replyMessageType = message.messageReplyType;
        dbMessageEntity.source = message.source;
        
        if (message.getGroupId != nil) {
            dbMessageEntity.groupId = message.groupId;
        }
        if (message.fileMeta != nil) {
            DB_FileMetaInfo *fileInfo =  [self createFileMetaInfoEntityForDBInsertionWithMessage:message.fileMeta];
            dbMessageEntity.fileMetaInfo = fileInfo;
        }
    }
    return dbMessageEntity;
}

- (DB_FileMetaInfo *)createFileMetaInfoEntityForDBInsertionWithMessage:(ALFileMetaInfo *)fileInfo {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    DB_FileMetaInfo *fileMetaInfo = (DB_FileMetaInfo *)[databaseHandler insertNewObjectForEntityForName:@"DB_FileMetaInfo"];
    
    if (fileMetaInfo) {
        fileMetaInfo.blobKeyString = fileInfo.blobKey;
        fileMetaInfo.thumbnailBlobKeyString = fileInfo.thumbnailBlobKey;
        fileMetaInfo.contentType = fileInfo.contentType;
        fileMetaInfo.createdAtTime = fileInfo.createdAtTime;
        fileMetaInfo.key = fileInfo.key;
        fileMetaInfo.name = fileInfo.name;
        fileMetaInfo.size = fileInfo.size;
        fileMetaInfo.suUserKeyString = fileInfo.userKey;
        fileMetaInfo.thumbnailUrl = fileInfo.thumbnailUrl;
        fileMetaInfo.url = fileInfo.url;
    }
    
    return fileMetaInfo;
}

- (ALMessage *)createMessageEntity:(DB_Message *)dbMessage {
    
    if (!dbMessage) {
        return nil;
    }
    
    ALMessage *newMessage = [ALMessage new];
    
    newMessage.msgDBObjectId = [dbMessage objectID];
    newMessage.key = dbMessage.key;
    newMessage.deviceKey = dbMessage.deviceKey;
    newMessage.userKey = dbMessage.userKey;
    newMessage.to = dbMessage.to;
    newMessage.message = dbMessage.messageText;
    newMessage.sendToDevice = dbMessage.isSentToDevice.boolValue;
    newMessage.shared = dbMessage.isShared.boolValue;
    newMessage.createdAtTime = dbMessage.createdAt;
    newMessage.type = dbMessage.type;
    newMessage.contactIds = dbMessage.contactId;
    newMessage.storeOnDevice = dbMessage.isStoredOnDevice.boolValue;
    newMessage.inProgress =dbMessage.inProgress.boolValue;
    newMessage.status = dbMessage.status;
    newMessage.imageFilePath = dbMessage.filePath;
    newMessage.delivered = dbMessage.delivered.boolValue;
    newMessage.sentToServer = dbMessage.sentToServer.boolValue;
    newMessage.isUploadFailed = dbMessage.isUploadFailed.boolValue;
    newMessage.contentType = dbMessage.contentType;
    
    newMessage.deleted = dbMessage.deletedFlag.boolValue;
    newMessage.groupId = dbMessage.groupId;
    newMessage.conversationId = dbMessage.conversationId;
    newMessage.pairedMessageKey = dbMessage.pairedMessageKey;
    newMessage.metadata = [newMessage getMetaDataDictionary:dbMessage.metadata];
    newMessage.msgHidden = [dbMessage.msgHidden boolValue];
    newMessage.source = [dbMessage source];
    newMessage.messageReplyType = dbMessage.replyMessageType;
    
    /// file meta info
    if (dbMessage.fileMetaInfo) {
        ALFileMetaInfo *fileMeta = [ALFileMetaInfo new];
        fileMeta.blobKey = dbMessage.fileMetaInfo.blobKeyString;
        fileMeta.thumbnailBlobKey = dbMessage.fileMetaInfo.thumbnailBlobKeyString;
        fileMeta.contentType = dbMessage.fileMetaInfo.contentType;
        fileMeta.createdAtTime = dbMessage.fileMetaInfo.createdAtTime;
        fileMeta.key = dbMessage.fileMetaInfo.key;
        fileMeta.name = dbMessage.fileMetaInfo.name;
        fileMeta.size = dbMessage.fileMetaInfo.size;
        fileMeta.userKey = dbMessage.fileMetaInfo.suUserKeyString;
        fileMeta.thumbnailUrl = dbMessage.fileMetaInfo.thumbnailUrl;
        fileMeta.thumbnailFilePath = dbMessage.fileMetaInfo.thumbnailFilePath;
        fileMeta.url = dbMessage.fileMetaInfo.url;
        newMessage.fileMeta = fileMeta;
    }
    return newMessage;
}

- (void)updateFileMetaInfo:(ALMessage *)message {
    DB_Message *dbMessage = (DB_Message *)[self getMeesageById:message.msgDBObjectId];
    if (dbMessage) {
        dbMessage.fileMetaInfo.key = message.fileMeta.key;
        dbMessage.fileMetaInfo.blobKeyString = message.fileMeta.blobKey;
        dbMessage.fileMetaInfo.thumbnailBlobKeyString = message.fileMeta.thumbnailBlobKey;
        dbMessage.fileMetaInfo.contentType = message.fileMeta.contentType;
        dbMessage.fileMetaInfo.createdAtTime = message.fileMeta.createdAtTime;
        dbMessage.fileMetaInfo.key = message.fileMeta.key;
        dbMessage.fileMetaInfo.name = message.fileMeta.name;
        dbMessage.fileMetaInfo.size = message.fileMeta.size;
        dbMessage.fileMetaInfo.suUserKeyString = message.fileMeta.userKey;
        dbMessage.fileMetaInfo.url = message.fileMeta.url;
        [[ALDBHandler sharedInstance] saveContext];
    }
}

- (NSMutableArray *)getMessageListForContactWithCreatedAt:(MessageListRequest *)messageListRequest {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate *predicate1;
    
    if ([ALApplozicSettings getContextualChatOption] &&
        messageListRequest.conversationId != nil &&
        messageListRequest.conversationId.integerValue != 0) {
        if (messageListRequest.channelKey != nil) {
            predicate1 = [NSPredicate predicateWithFormat:@"groupId = %@ && conversationId = %i",messageListRequest.channelKey,messageListRequest.conversationId];
        } else {
            predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@ && conversationId = %i",messageListRequest.userId,messageListRequest.conversationId];
        }
    } else if (messageListRequest.channelKey != nil) {
        predicate1 = [NSPredicate predicateWithFormat:@"groupId = %@",messageListRequest.channelKey];
    } else {
        predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@ && groupId = nil ",messageListRequest.userId];
    }
    
    NSPredicate *predicateDeletedCheck=[NSPredicate predicateWithFormat:@"deletedFlag == NO"];
    
    NSPredicate *predicateForHiddenMessages = [NSPredicate predicateWithFormat:@"msgHidden == %@", @(NO)];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"createdAt < 0"];
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2, predicateDeletedCheck,predicateForHiddenMessages]];
    
    if (messageListRequest.endTimeStamp
        != nil) {
        NSPredicate *predicateForEndTimeStamp= [NSPredicate predicateWithFormat:@"createdAt < %@",messageListRequest.endTimeStamp];
        compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicateForEndTimeStamp, predicateDeletedCheck,predicateForHiddenMessages]];
    }
    
    if (messageListRequest.startTimeStamp != nil) {
        NSPredicate *predicateCreatedAtForStartTime  = [NSPredicate predicateWithFormat:@"createdAt >= %@",messageListRequest.startTimeStamp];
        compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicateCreatedAtForStartTime, predicateDeletedCheck,predicateForHiddenMessages]];
    }
    messageFetchRequest.predicate = compoundPredicate;
    
    [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    messageFetchRequest.fetchLimit = 200;
    
    NSArray *messageArray = [databaseHandler executeFetchRequest:messageFetchRequest withError:nil];
    NSMutableArray *msgArray = [[NSMutableArray alloc] init];
    if (messageArray.count) {
        for (DB_Message *theEntity in messageArray) {
            ALMessage *message = [self createMessageEntity:theEntity];
            [msgArray addObject:message];
        }
    }
    return msgArray;
}

#pragma mark - Get all attachment messages

- (NSMutableArray *)getAllMessagesWithAttachmentForContact:(NSString *)contactId
                                             andChannelKey:(NSNumber *)channelKey
                                 onlyDownloadedAttachments:(BOOL)onlyDownloaded {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate *predicate1;
    
    if (channelKey != nil) {
        predicate1 = [NSPredicate predicateWithFormat:@"groupId = %@", channelKey];
    } else {
        predicate1 = [NSPredicate predicateWithFormat:@"contactId = %@", contactId];
    }
    
    NSPredicate *predicateDeletedCheck =[NSPredicate predicateWithFormat:@"deletedFlag == NO"];
    
    NSPredicate *predicateForFileMeta = [NSPredicate predicateWithFormat:@"fileMetaInfo != nil"];
    NSMutableArray *predicates = [[NSMutableArray alloc] initWithArray: @[predicate1, predicateDeletedCheck, predicateForFileMeta]];
    
    if (onlyDownloaded) {
        NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"filePath != nil"];
        [predicates addObject:predicate2];
    }
    
    messageFetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    NSArray *messages = [databaseHandler executeFetchRequest:messageFetchRequest withError:nil];
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    if (messages.count > 0) {
        for (DB_Message * theEntity in messages) {
            ALMessage *message = [self createMessageEntity:theEntity];
            [messageArray addObject:message];
        }
    }
    
    return messageArray;
}


#pragma mark - Pending messages

- (NSMutableArray *)getPendingMessages {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    messageFetchRequest.predicate = [NSPredicate predicateWithFormat:@"sentToServer = %@ and type= %@ and deletedFlag = %@",@"0",@"5",@(NO)];
    
    [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    
    NSArray *messages = [databaseHandler executeFetchRequest:messageFetchRequest withError:nil];
    
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    
    if (messages.count > 0) {
        for (DB_Message *dbMessage in messages) {
            ALMessage *message = [self createMessageEntity:dbMessage];
            if ([message.groupId isEqualToNumber:[NSNumber numberWithInt:0]]) {
                ALSLog(ALLoggerSeverityInfo, @"groupId is coming as 0..setting it null" );
                message.groupId = NULL;
            }
            [messageArray addObject:message];
            ALSLog(ALLoggerSeverityInfo, @"Pending Message status:%@",message.status);
        }
    }
    
    ALSLog(ALLoggerSeverityInfo, @"Found the number of pending messages: %lu",(unsigned long)messageArray.count);
    return messageArray;
}

- (NSUInteger)getMessagesCountFromDBForUser:(NSString *)userId {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contactId = %@ && groupId = nil",userId];
    [messageFetchRequest setPredicate:predicate];
    NSUInteger count = [databaseHandler countForFetchRequest:messageFetchRequest];
    return count;
    
}

#pragma mark - Get latest message for User/Channel

- (ALMessage *)getLatestMessageForUser:(NSString *)userId {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contactId = %@ and groupId = nil and deletedFlag = %@",userId,@(NO)];
    [messageFetchRequest setPredicate:predicate];
    [messageFetchRequest setFetchLimit:1];
    [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    
    NSError *fetchError = nil;
    NSArray *messagesArray = [databaseHandler executeFetchRequest:messageFetchRequest withError:&fetchError];
    
    if (messagesArray.count) {
        DB_Message *dbMessage = [messagesArray objectAtIndex:0];
        ALMessage *message = [self createMessageEntity:dbMessage];
        return message;
    }
    
    return nil;
}

- (ALMessage *)getLatestMessageForChannel:(NSNumber *)channelKey
                 excludeChannelOperations:(BOOL)flag {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupId = %@ and deletedFlag = %@",channelKey,@(NO)];
    
    if (flag) {
        predicate = [NSPredicate predicateWithFormat:@"groupId = %@ and deletedFlag = %@ and contentType != %i",channelKey,@(NO),ALMESSAGE_CHANNEL_NOTIFICATION];
    }
    
    [messageFetchRequest setPredicate:predicate];
    [messageFetchRequest setFetchLimit:1];
    
    [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    
    NSError *fetchError = nil;
    NSArray *messagesArray = [databaseHandler executeFetchRequest:messageFetchRequest withError:&fetchError];
    
    if (messagesArray.count) {
        DB_Message *dbMessage = [messagesArray objectAtIndex:0];
        ALMessage *message = [self createMessageEntity:dbMessage];
        return message;
    }
    
    return nil;
}


/////////////////////////////  FETCH CONVERSATION WITH PAGE SIZE  /////////////////////////////

- (void)fetchConversationfromServerWithCompletion:(void(^)(BOOL flag))completionHandler {
    [self syncConverstionDBWithCompletion:^(BOOL success, NSMutableArray *messages) {
        
        if (!success) {
            completionHandler(success);
            return;
        }
        
        [self addMessageList:messages skipAddingMessageInDb:NO];
        [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
        [self fetchConversationsGroupByContactId];
        
        completionHandler(success);
        
    }];
}

/************************************
 FETCH LATEST MESSSAGE FOR SUB GROUPS
 ************************************/

- (void)fetchSubGroupConversations:(NSMutableArray *)subGroupList {
    NSMutableArray *subGroupMessageArray = [NSMutableArray new];
    
    for (ALChannel *channel in subGroupList) {
        ALMessage *message = [self getLatestMessageForChannel:channel.key excludeChannelOperations:NO];
        if (message) {
            [subGroupMessageArray addObject:message];
            if (channel.type == GROUP_OF_TWO) {
                NSMutableArray *clientKeyArray = [[channel.clientChannelKey componentsSeparatedByString:@":"] mutableCopy];
                
                if (![clientKeyArray containsObject:[ALUserDefaultsHandler getUserId]]) {
                    [subGroupMessageArray removeObject:message];
                }
            }
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:NO];
    NSArray *sortedMessageArray = [NSArray arrayWithObject:sortDescriptor];
    NSMutableArray *sortedArray = [[subGroupMessageArray sortedArrayUsingDescriptors:sortedMessageArray] mutableCopy];
    
    if ([self.delegate respondsToSelector:@selector(getMessagesArray:)]) {
        [self.delegate getMessagesArray:sortedArray];
    }
}

- (void)updateMessageReplyType:(NSString *)messageKeyString replyType:(NSNumber *)type hideFlag:(BOOL)flag {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    
    DB_Message *replyMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageKeyString];
    
    if (replyMessage) {
        replyMessage.replyMessageType = type;
        replyMessage.msgHidden = [NSNumber numberWithBool:flag];
        
        NSError *error = [databaseHandler saveContext];
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Unable to save replytype  %@, %@", error, error.localizedDescription);
        }
    }
}

#pragma mark - Get message by message key

- (ALMessage*)getMessageByKey:(NSString *)messageKey {
    DB_Message *dbMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageKey];
    return [self createMessageEntity:dbMessage];
}

- (void)updateMessageSentDetails:(NSString *)messageKeyString withCreatedAtTime:(NSNumber *)createdAtTime withDbMessage:(DB_Message *)dbMessage {
    
    if (!dbMessage) {
        return;
    }
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    dbMessage.key = messageKeyString;
    dbMessage.inProgress = [NSNumber numberWithBool:NO];
    dbMessage.isUploadFailed = [NSNumber numberWithBool:NO];
    dbMessage.createdAt = createdAtTime;
    
    dbMessage.sentToServer=[NSNumber numberWithBool:YES];
    dbMessage.status = [NSNumber numberWithInt:SENT];
    [databaseHandler saveContext];
}

#pragma mark - Message list

- (void)getLatestMessages:(BOOL)isNextPage withCompletionHandler:(void(^)(NSMutableArray *messages, NSError *error)) completion {
    
    if (!isNextPage) {
        
        if ([self isMessageTableEmpty] ||
            ![ALUserDefaultsHandler isInitialMessageListCallDone]) {
            [self fetchAndRefreshFromServerWithCompletion:^(NSMutableArray *messages, NSError *error) {
                completion(messages, error);
            }];
        } else {
            completion([self fetchLatestConversationsGroupByContactId:NO], nil);
        }
    } else {
        [self fetchAndRefreshFromServerWithCompletion:^(NSMutableArray *messages, NSError *error) {
            completion(messages, error);
        }];
    }
}

- (void)fetchAndRefreshFromServerWithCompletion:(void(^)(NSMutableArray *messages, NSError *error)) completion {
    
    if (![ALUserDefaultsHandler getFlagForAllConversationFetched]) {
        [self getLatestMessagesWithCompletion:^(NSMutableArray *messages, NSError *error) {
            
            if (!error) {
                // save data into the db
                [self addMessageList:messages skipAddingMessageInDb:NO];
                // set yes to userdefaults
                [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
                // add default contacts
                //fetch data from db
                completion([self fetchLatestConversationsGroupByContactId:YES], error);
                return;
            } else {
                completion(nil, error);
            }
        }];
    } else {
        completion(nil, nil);
    }
}

#pragma mark - Message list for one to one or Channel/Group

- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler:(void(^)(NSMutableArray *messages, NSError *error)) completion {
    
    if (!isNextPage) {
        
        if ([self isMessageTableEmpty] ||
            ![ALUserDefaultsHandler isInitialMessageListCallDone]) {
            [self fetchLatestMesssagesFromServer:isGroup withCompletion:^(NSMutableArray *messages, NSError *error) {
                completion(messages,error);
            }];
        } else {
            completion([self fetchLatestMesssagesFromDb:isGroup], nil);
        }
    } else {
        [self fetchLatestMesssagesFromServer:isGroup withCompletion:^(NSMutableArray *messages, NSError *error) {
            completion(messages, error);
        }];
    }
}

- (void)fetchLatestMesssagesFromServer:(BOOL)isGroupMesssages
                        withCompletion:(void(^)(NSMutableArray *messages, NSError *error)) completion {
    
    if (![ALUserDefaultsHandler getFlagForAllConversationFetched]) {
        [self getLatestMessagesWithCompletion:^(NSMutableArray *messages, NSError *error) {
            
            if (!error) {
                // save data into the db
                [self addMessageList:messages skipAddingMessageInDb:NO];
                // set yes to userdefaults
                [ALUserDefaultsHandler setBoolForKey_isConversationDbSynced:YES];
                // add default contacts
                //fetch data from db
                completion([self fetchLatestMesssagesFromDb:isGroupMesssages], error);
                return;
            } else {
                completion(nil, error);
            }
        }];
    } else {
        completion(nil, nil);
    }
}

- (NSMutableArray *)fetchLatestMesssagesFromDb:(BOOL)isGroupMessages {
    
    NSMutableArray *messagesArray = nil;
    
    if (isGroupMessages) {
        messagesArray =  [self getLatestMessagesForGroup];
    } else {
        messagesArray = [self getLatestMessagesForContact];
    }
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:NO];
    NSArray *sortedMessageArray = [NSArray arrayWithObject:sortDescriptor];
    NSMutableArray *sortedArray = [[messagesArray sortedArrayUsingDescriptors:sortedMessageArray] mutableCopy];
    
    return sortedArray;
}

- (NSMutableArray *)getLatestMessagesForContact {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSMutableArray *messagesArray = [NSMutableArray new];
    
    // Find all message only have contact ...
    NSFetchRequest *dbMessageRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [dbMessageRequest setResultType:NSDictionaryResultType];
    [dbMessageRequest setPredicate:[NSPredicate predicateWithFormat:@"groupId=%d OR groupId=nil",0]];
    [dbMessageRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [dbMessageRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"contactId", nil]];
    [dbMessageRequest setReturnsDistinctResults:YES];
    
    NSError *fetchError = nil;
    NSArray *userMessageArray = [databaseHandler executeFetchRequest:dbMessageRequest withError:&fetchError];
    
    if (fetchError) {
        ALSLog(ALLoggerSeverityError, @"Failed to fetch Latest Messages For Contact : %@", fetchError);
        return messagesArray;
    }
    
    for (NSDictionary *messageDictionary in userMessageArray) {
        
        NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
        [messageFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"contactId = %@ and groupId=nil and deletedFlag == %@ AND contentType != %i AND msgHidden == %@",messageDictionary[@"contactId"],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
        
        [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
        [messageFetchRequest setFetchLimit:1];
        
        NSArray *fetchArray = [databaseHandler executeFetchRequest:messageFetchRequest withError:nil];
        
        if (fetchArray.count) {
            DB_Message *dbMessageEntity = fetchArray.firstObject;
            ALMessage *message = [self createMessageEntity:dbMessageEntity];
            [messagesArray addObject:message];
        }
    }
    return messagesArray;
}

- (NSMutableArray *)getLatestMessagesForGroup {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    NSMutableArray *messagesArray = [NSMutableArray new];
    
    // get all unique contacts
    NSFetchRequest *dbMessageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
    [dbMessageFetchRequest setResultType:NSDictionaryResultType];
    [dbMessageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [dbMessageFetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"groupId", nil]];
    [dbMessageFetchRequest setReturnsDistinctResults:YES];
    
    NSError *fetchError = nil;
    NSArray *messageArray = [databaseHandler executeFetchRequest:dbMessageFetchRequest withError:&fetchError];
    
    if (fetchError) {
        ALSLog(ALLoggerSeverityError, @"Failed to fetch the message array %@", fetchError);
        return messagesArray;
    }
    
    // get latest record
    for (NSDictionary *messageDictionary in messageArray) {
        NSFetchRequest *messageFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DB_Message"];
        
        if ([messageDictionary[@"groupId"] intValue] == 0) {
            continue;
        }
        
        if ([ALApplozicSettings getCategoryName]) {
            ALChannel *channel = [[ALChannelService new] getChannelByKey:[NSNumber numberWithInt:[messageDictionary[@"groupId"] intValue]]];
            if (![channel isPartOfCategory:[ALApplozicSettings getCategoryName]]) {
                continue;
            }
        }
        [messageFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
        [messageFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"groupId==%d AND deletedFlag == %@ AND contentType != %i AND msgHidden == %@",
                                           [messageDictionary[@"groupId"] intValue],@(NO),ALMESSAGE_CONTENT_HIDDEN,@(NO)]];
        [messageFetchRequest setFetchLimit:1];
        
        NSArray *groupMessageArray = [databaseHandler executeFetchRequest:messageFetchRequest withError:nil];
        if (groupMessageArray.count) {
            DB_Message *dbMessageEntity = groupMessageArray.firstObject;
            ALMessage *message = [self createMessageEntity:dbMessageEntity];
            [messagesArray addObject:message];
        }
    }
    return messagesArray;
}

- (ALMessage *)handleMessageFailedStatus:(ALMessage *)message {
    if (!message.msgDBObjectId) {
        return nil;
    }
    message.inProgress = NO;
    message.isUploadFailed = YES;
    message.sentToServer = NO;
    DB_Message *dbMessage = (DB_Message *)[self getMessageByKey:@"key" value:message.key];
    if (dbMessage) {
        dbMessage.inProgress = [NSNumber numberWithBool:NO];
        dbMessage.isUploadFailed = [NSNumber numberWithBool:YES];
        dbMessage.sentToServer= [NSNumber numberWithBool:NO];
        [[ALDBHandler sharedInstance] saveContext];
    }
    return message;
}

- (ALMessage *)writeDataAndUpdateMessageInDB:(NSData *)data
                                 withMessage:(ALMessage *)message
                                withFileFlag:(BOOL)isFile {
    ALMessage *messageObject = message;
    DB_Message *messageEntity = (DB_Message *)[self getMessageByKey:@"key" value:messageObject.key];
    
    NSData *imageData;
    if (![messageObject.fileMeta.contentType hasPrefix:@"image"]) {
        imageData = data;
    } else {
        imageData = [ALUtilityClass compressImage:data];
    }
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *componentsArray = [messageObject.fileMeta.name componentsSeparatedByString:@"."];
    NSString *fileExtension = [componentsArray lastObject];
    NSString *filePath;
    
    if (isFile) {
        filePath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_local.%@", messageObject.key, fileExtension]];
        
        // If 'save video to gallery' is enabled then save to gallery
        if ([ALApplozicSettings isSaveVideoToGalleryEnabled]) {
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, self, nil, nil);
        }
        
        NSString *fileName = [NSString stringWithFormat:@"%@_local.%@", messageObject.key, fileExtension];
        if (messageEntity) {
            messageEntity.inProgress = [NSNumber numberWithBool:NO];
            messageEntity.isUploadFailed = [NSNumber numberWithBool:NO];
            messageEntity.filePath = fileName;
        } else {
            messageObject.inProgress = NO;
            messageObject.isUploadFailed = NO;
            messageObject.imageFilePath = fileName;
        }
    } else {
        filePath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_thumbnail_local.%@", messageObject.key, fileExtension]];
        
        NSString *fileName = [NSString stringWithFormat:@"%@_thumbnail_local.%@", messageObject.key, fileExtension];
        if (messageEntity) {
            messageEntity.fileMetaInfo.thumbnailFilePath = fileName;
        } else {
            messageObject.fileMeta.thumbnailFilePath = fileName;
        }
    }
    
    [imageData writeToFile:filePath atomically:YES];
    
    if (messageEntity) {
        [[ALDBHandler sharedInstance] saveContext];
        return [[ALMessageDBService new] createMessageEntity:messageEntity];
    }
    return messageObject;
}

- (DB_Message *)addAttachmentMessage:(ALMessage *)message {
    
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    DB_Message *dbMessageEntity = [messageDBService createMessageEntityForDBInsertionWithMessage:message];
    
    if (dbMessageEntity) {
        message.msgDBObjectId = [dbMessageEntity objectID];
        dbMessageEntity.inProgress = [NSNumber numberWithBool:YES];
        dbMessageEntity.isUploadFailed = [NSNumber numberWithBool:NO];
        NSError *error = [databaseHandler saveContext];
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Failed to save the Attachment Message : %@", message.key);
            return nil;
        }
    }
    return dbMessageEntity;
}

#pragma mark - Update message metadata

- (void)updateMessageMetadataOfKey:(NSString *)messageKey
                      withMetadata:(NSMutableDictionary *)metadata {
    ALSLog(ALLoggerSeverityInfo, @"Updating message metadata in local db for key : %@", messageKey);
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    
    DB_Message *dbMessage = (DB_Message *)[self getMessageByKey:@"key" value:messageKey];
    if (dbMessage) {
        dbMessage.metadata = metadata.description;
        if (metadata != nil && [metadata objectForKey:@"hiddenStatus"] != nil) {
            dbMessage.msgHidden = [NSNumber numberWithBool: [[metadata objectForKey:@"hiddenStatus"] isEqualToString:@"true"]];
        }
        
        NSError *error = [databaseHandler saveContext];
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Unable to save metadata in local db : %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"Message metadata has been updated successfully in local db");
        }
    }
}

@end
