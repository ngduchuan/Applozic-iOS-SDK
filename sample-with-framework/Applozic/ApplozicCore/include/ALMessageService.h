//
// ALMessageService.h
// ALChat
//
// Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALChannelService.h"
#import "ALConstant.h"
#import "ALConversationProxy.h"
#import "ALMessage.h"
#import "ALMessageClientService.h"
#import "ALMessageInfoResponse.h"
#import "ALMessageList.h"
#import "ALMQTTConversationService.h"
#import "ALRealTimeUpdate.h"
#import "ALSyncMessageFeed.h"
#import "ALUserDetail.h"
#import "ALUserService.h"
#import "DB_FileMetaInfo.h"
#import <Foundation/Foundation.h>
#import "MessageListRequest.h"

NS_ASSUME_NONNULL_BEGIN

/// Notification name for new message.
static NSString *const NEW_MESSAGE_NOTIFICATION = @"newMessageNotification";
/// Notification name for the message metadata update.
static NSString *const AL_MESSAGE_META_DATA_UPDATE = @"messageMetaDataUpdateNotification";

/// `ALMessageService` class has major methods for message API's
@interface ALMessageService : NSObject

+ (ALMessageService *)sharedInstance;

@property (nonatomic, strong) ALMessageClientService *messageClientService;
@property (nonatomic, strong) ALUserService *userService;
@property (nonatomic, strong) ALChannelService *channelService;

@property (nonatomic, weak) id<ApplozicUpdatesDelegate> _Nullable delegate;

/// Gets the messages for the one-to-one or group chat from the server.
/// @param messageListRequest Pass the MessageListRequest in case of one-to-one pass the userId or channelKey in case of a group.
/// @param completion If messages are fetched successfully, it will have a list of ALMessage objects; else, it will have NSError in case any error comes.
- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
               withCompletion:(void(^)(NSMutableArray * _Nullable messages, NSError * _Nullable error, NSMutableArray * _Nullable userDetailArray)) completion;

+ (void)getMessageListForContactId:(NSString * _Nullable)contactIds
                           isGroup:(BOOL)isGroup
                        channelKey:(NSNumber * _Nullable)channelKey
                    conversationId:(NSNumber * _Nullable)conversationId
                        startIndex:(NSInteger)startIndex
                    withCompletion:(void (^)(NSMutableArray * _Nullable messages))completion;

/// Sends text message in one to one or group conversation.
/// @param message Pass the ALMessage object for sending a text message.
/// @param completion If success in sending a message the NSError will be nil; else, if there is an error in sending a message the NSError will not be nil.
- (void)sendMessages:(ALMessage *)message withCompletion:(void(^)(NSString * _Nullable message, NSError * _Nullable error)) completion;

+ (void)getLatestMessageForUser:(NSString *)deviceKeyString withCompletion:(void(^)(NSMutableArray * _Nullable messages, NSError * _Nullable error)) completion;

+ (ALMessage *)processFileUploadSucess:(ALMessage *)message;

/// Deletes the conversation thread in a one-to-one or group chat.
/// @param contactId Pass the userId in case deleting the conversation for one-to-one; otherwise, it will be nil.
/// @param channelKey Pass the channelKey in case of deleting conversation for group chat, else it will be nil.
/// @param completion If success in deleting the thread then NSError is nil; else, if failure in deleting then NSError will not be nil.
- (void)deleteMessageThread:(NSString * _Nullable )contactId
               orChannelKey:(NSNumber * _Nullable )channelKey
             withCompletion:(void (^)(NSString * _Nullable response, NSError * _Nullable error))completion;

/// Deletes the message for given message key.
/// @param keyString Pass the message key from the message object to delete the message.
/// @param contactId Pass it as nil.
/// @param completion If success in deleting the message then error is nil else on failure in deleting NSError will not be nil.
- (void)deleteMessage:(NSString *)keyString
         andContactId:(NSString * _Nullable )contactId
       withCompletion:(void (^)(NSString * _Nullable response, NSError * _Nullable error))completion;

/// Sends the pending messages.
- (void)processPendingMessages;

+ (ALMessage *)getMessagefromKeyValuePair:(NSString *)key andValue:(NSString *)value;

/// Gets the message information which will have delivered and read for users in group chat.
/// @param messageKey Pass the message key from the message object.
/// @param completion If success in fetching the message information then NSError will be nil else on failure in fetching message information then NSError will not be nil.
- (void)getMessageInformationWithMessageKey:(NSString *)messageKey
                      withCompletionHandler:(void(^)(ALMessageInfoResponse * _Nullable messageInfoResponse, NSError * _Nullable error))completion;

+ (void)multiUserSendMessage:(ALMessage *)message
                  toContacts:(NSMutableArray *)contactIdsArray
                    toGroups:(NSMutableArray *)channelKeysArray
              withCompletion:(void(^)(NSString *jsonResponse, NSError *error)) completion;

+ (void)getMessageSENT:(ALMessage *)message withCompletion:(void (^)(NSMutableArray * _Nullable messages, NSError * _Nullable error))completion;

+ (void)getMessageSENT:(ALMessage *)message
          withDelegate:(id<ApplozicUpdatesDelegate> _Nullable)delegate
        withCompletion:(void (^)(NSMutableArray * _Nullable messages, NSError * _Nullable error))completion;

+ (ALMessage *)createCustomTextMessageEntitySendTo:(NSString *)to withText:(NSString *)text;

- (void)getMessageListForUserIfLastIsHiddenMessageinMessageList:(ALMessageList *)messageList
                                                 withCompletion:(void (^)(NSMutableArray * _Nullable messages,
                                                                          NSError * _Nullable error,
                                                                          NSMutableArray * _Nullable userDetailArray))completion;

- (void)getMessagesListGroupByContactswithCompletionService:(void(^)(NSMutableArray * _Nullable messages, NSError * _Nullable error))completion;

+ (ALMessage *)createHiddenMessageEntitySentTo:(NSString *)to withText:(NSString *)text;

+ (ALMessage *)createMessageWithMetaData:(NSMutableDictionary *)metaData
                          andContentType:(short)contentType
                           andReceiverId:(NSString *)receiverId
                          andMessageText:(NSString *)messageText;


/// Returns total number of messages.
/// @param userId Pass the receiver userId.
- (NSUInteger)getMessagsCountForUser:(NSString *)userId;

- (ALMessage *)getLatestMessageForUser:(NSString *)userId;

- (ALMessage *)getLatestMessageForChannel:(NSNumber *)channelKey excludeChannelOperations:(BOOL)flag;

+ (void)syncMessages;

+ (void)getLatestMessageForUser:(NSString *)deviceKeyString
                   withDelegate:(id<ApplozicUpdatesDelegate> _Nullable )delegate
                 withCompletion:(void (^)(NSMutableArray * _Nullable messages, NSError * _Nullable error))completion;

/// Gets the recent messages for contact or group.
/// @param isNextPage If you want to load the next set of messages pass YES or true to load else pass NO or false.
/// @param isGroup To get groups messages only then pass YES or true it will give group latest messages else
/// to get only user latest messages then pass NO or false.
/// @param completion Array of messages of type ALMessage and error if failed to get the messages.
- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler:(void(^)(NSMutableArray * _Nullable messages, NSError * _Nullable error)) completion;

+ (void)addOpenGroupMessage:(ALMessage *)message
               withDelegate:(id<ApplozicUpdatesDelegate> _Nullable )delegate
             withCompletion:(void (^)(BOOL success))completion;

- (ALMessage *)handleMessageFailedStatus:(ALMessage *)message;

/// Returns `ALMessage` object for given message key.
- (ALMessage *)getMessageByKey:(NSString *)messageKey;

/// Syncs the messages where metadata is updated.
/// @param deviceKeyString Pass the [ALUserDefaultsHandler getDeviceKeyString].
/// @param completion If error in syncing a updated meta data messages then NSError will be their else a array of messages if their is no error in syncing a updated meta data messages.
+ (void)syncMessageMetaData:(NSString *)deviceKeyString withCompletion:(void (^)(NSMutableArray *messages, NSError *error))completion;

/// Updates message metadata for given message key.
/// @param messageKey Pass the message key for updating message meta data.
/// @param metadata Pass the updated message metadata for updating.
/// @param completion If an error in deleting a message for all then NSError will not be nil else on successful delete error will be nil.
- (void)updateMessageMetadataOfKey:(NSString *)messageKey
                      withMetadata:(NSMutableDictionary *)metadata
                    withCompletion:(void(^)(ALAPIResponse * _Nullable apiResponse, NSError * _Nullable error)) completion;

/// Gets messages by message keys.
/// @param keys Pass the array of message keys.
/// @param completion If there is no error in fetching messages, then it will have an array of messages. else it will have nil.
- (void)fetchReplyMessages:(NSMutableArray<NSString *> *)keys withCompletion: (void(^)(NSMutableArray<ALMessage *> * _Nullable messages))completion;

/// Deletes the message for all in channel conversation.
/// @param keyString Pass the message key from ALMessage object.
/// @param completion If an error in deleting a message for all then NSError will not be nil else on successful delete error will be nil.
- (void)deleteMessageForAllWithKey:(NSString *)keyString
                    withCompletion:(void (^)(ALAPIResponse * _Nullable apiResponse, NSError * _Nullable error))completion;

/// Total unread message count.
/// @param completion will have a total unread message count if there is no error in fetching.
- (void)getTotalUnreadMessageCountWithCompletionHandler:(void (^)(NSUInteger unreadCount, NSError * _Nullable error))completion;

/// Total unread conversation count.
/// @param completion will have a total unread conversation count if there is no error in fetching.
- (void)getTotalUnreadConversationCountWithCompletionHandler:(void (^)(NSUInteger conversationUnreadCount, NSError * _Nullable error))completion;

/// Returns `ALMessage` object for given message key.
- (ALMessage *)getALMessageByKey:(NSString *)messageReplyId DEPRECATED_MSG_ATTRIBUTE("Use getMessageByKey: instead");

@end

NS_ASSUME_NONNULL_END
