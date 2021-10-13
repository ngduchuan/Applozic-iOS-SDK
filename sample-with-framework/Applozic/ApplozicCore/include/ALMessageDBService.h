//
//  ALMessageDBService.h
//  ChatApp
//
//  Created by Devashish on 21/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALConversationListRequest.h"
#import "ALFileMetaInfo.h"
#import "ALMessage.h"
#import "DB_FileMetaInfo.h"
#import "DB_Message.h"
#import <Foundation/Foundation.h>
#import "MessageListRequest.h"

@class ALMessageService;

@protocol ALMessagesDelegate <NSObject>

- (void)getMessagesArray:(NSMutableArray *)messagesArray;

- (void)updateMessageList:(NSMutableArray *)messagesArray;

@end

@interface ALMessageDBService : NSObject

@property(nonatomic,weak) id <ALMessagesDelegate>delegate;

@property(nonatomic, retain) ALMessageService *messageService;

//Add Message APIS
- (NSMutableArray *)addMessageList:(NSMutableArray *)messageList skipAddingMessageInDb:(BOOL)skip;
- (DB_Message *)addMessage:(ALMessage *)message;
- (void)getMessages:(NSMutableArray *)subGroupList;
- (void)fetchConversationsGroupByContactId;
- (void)fetchAndRefreshQuickConversationWithCompletion:(void (^)(NSMutableArray *messages, NSError *error))completion;
- (void)fetchAndRefreshFromServerWithCompletion:(void(^)(NSMutableArray *messages, NSError *error)) completion;
- (void)getLatestMessagesWithCompletion:(void(^)(NSMutableArray *messages, NSError *error)) completion;

- (NSManagedObject *)getMeesageById:(NSManagedObjectID *)objectID;
- (NSManagedObject *)getMessageByKey:(NSString *)key value:(NSString *)value;

- (NSMutableArray *)getMessageListForContactWithCreatedAt:(MessageListRequest *)messageListRequest;

- (NSMutableArray *)getAllMessagesWithAttachmentForContact:(NSString *)contactId
                                             andChannelKey:(NSNumber *)channelKey
                                 onlyDownloadedAttachments:(BOOL)onlyDownloaded;

- (NSMutableArray *)getPendingMessages;

/**
 * Returns a list of last messages (Group by Contact)
 *
 * @param messageCount The Number of messages required.
 * @param received If YES, messages will be of type received. If NO, then messages can be of type received or sent.
 * @return An array containing the list of messages.
 */
- (NSArray *)getMessageList:(int)messageCount
    messageTypeOnlyReceived:(BOOL)received;

//update Message APIS
- (void)updateMessageDeliveryReport:(NSString *)messageKeyString withStatus:(int)status;
- (void)updateDeliveryReportForContact:(NSString *)contactId withStatus:(int)status;
- (void)updateMessageSyncStatus:(NSString *)keyString;
- (void)updateFileMetaInfo:(ALMessage *)message;

//Delete Message APIS
- (void)deleteMessageByKey:(NSString *)keyString;
- (void)deleteAllMessagesByContact:(NSString *)contactId orChannelKey:(NSNumber *)key;

//Generic APIS
- (BOOL)isMessageTableEmpty;
- (void)deleteAllObjectsInCoreData;

- (DB_Message *)createMessageEntityForDBInsertionWithMessage:(ALMessage *)message;
- (DB_FileMetaInfo *)createFileMetaInfoEntityForDBInsertionWithMessage:(ALFileMetaInfo *)fileInfo;
- (ALMessage *)createMessageEntity:(DB_Message *)dbMessage;
- (ALMessage*)getMessageByKey:(NSString *)messageKey;

- (NSMutableArray *)fetchLatestConversationsGroupByContactId :(BOOL)isFetchOnCreatedAtTime;

- (void)fetchConversationfromServerWithCompletion:(void(^)(BOOL flag))completionHandler;

- (NSUInteger)getMessagesCountFromDBForUser:(NSString *)userId;

- (ALMessage *)getLatestMessageForUser:(NSString *)userId;

- (ALMessage *)getLatestMessageForChannel:(NSNumber *)channelKey excludeChannelOperations:(BOOL)flag;

- (void)updateMessageReplyType:(NSString *)messageKeyString replyType:(NSNumber *)type hideFlag:(BOOL)flag;

- (void)updateMessageSentDetails:(NSString *)messageKeyString
               withCreatedAtTime:(NSNumber *)createdAtTime
                   withDbMessage:(DB_Message *)dbMessage;

- (void)getLatestMessages:(BOOL)isNextPage withCompletionHandler:(void(^)(NSMutableArray *messages, NSError *error)) completion;

- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler:(void(^)(NSMutableArray *messages, NSError *error)) completion;

- (ALMessage *)handleMessageFailedStatus:(ALMessage *)message;

- (DB_Message *)addAttachmentMessage:(ALMessage *)message;

- (void)updateMessageMetadataOfKey:(NSString *)messageKey withMetadata:(NSMutableDictionary *)metadata;

- (ALMessage *)writeDataAndUpdateMessageInDb:(NSData *)data withMessage:(ALMessage *)message withFileFlag:(BOOL)isFile;

/// Returns a list of last messages for group and contact based on the startTime or endTime
/// @param conversationListRequest Used for passing the startTime or endTime
- (NSMutableArray *)fetchLatestMessagesFromDatabaseWithRequestList:(ALConversationListRequest *)conversationListRequest;

@end
