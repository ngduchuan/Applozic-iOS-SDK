//
//  ALMessageClientService.h
//  ChatApp
//
//  Created by devashish on 02/10/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALContactDBService.h"
#import "ALMessage.h"
#import "ALMessageInfoResponse.h"
#import "ALMessageList.h"
#import "ALResponseHandler.h"
#import "ALSearchRequest.h"
#import "ALSyncMessageFeed.h"
#import <Foundation/Foundation.h>
#import "MessageListRequest.h"

@interface ALMessageClientService : NSObject

@property (nonatomic, strong) ALResponseHandler *responseHandler;

- (void)addWelcomeMessage:(NSNumber *)channelKey;

- (void)getLatestMessageGroupByContact:(NSUInteger)mainPageSize
                             startTime:(NSNumber *)startTime
                        withCompletion:(void(^)(ALMessageList *messageList, NSError *error))completion;

- (void)getMessagesListGroupByContactswithCompletion:(void(^)(NSMutableArray *messages, NSError *error)) completion;

- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
               withCompletion:(void (^)(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray))completion;

- (void)sendPhotoForUserInfo:(NSDictionary *)messageDictionary withCompletion:(void(^)(NSString *message, NSError *error)) completion;

- (void)getLatestMessageForUser:(NSString *)deviceKeyString withCompletion:(void (^)(ALSyncMessageFeed *syncMessageFeed, NSError *error))completion;

- (void)deleteMessage:(NSString *)keyString
         andContactId:(NSString *)contactId
       withCompletion:(void (^)(NSString *response, NSError *error))completion;

- (void)deleteMessageThread:(NSString *)contactId
               orChannelKey:(NSNumber *)channelKey
             withCompletion:(void (^)(NSString *response, NSError *error))completion;

- (void)sendMessage:(NSDictionary *)userInfo withCompletionHandler:(void(^)(id jsonResponse, NSError *error))completion;

- (void)getCurrentMessageInformation:(NSString *)messageKey
               withCompletionHandler:(void(^)(ALMessageInfoResponse *messageInfoResponse, NSError *error))completion;

- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
                withOpenGroup:(BOOL)isOpenGroup
               withCompletion:(void (^)(NSMutableArray *messages, NSError *error, NSMutableArray *userDetails))completion;

- (void)downloadImageUrl:(NSString *)blobKey withCompletion:(void(^)(NSString *fileURL, NSError *error)) completion;

- (void)downloadImageThumbnailUrl:(NSString *)url
                          blobKey:(NSString *)blobKey
                       completion:(void(^)(NSString *fileURL, NSError *error)) completion;

- (void)downloadImageThumbnailUrl:(ALMessage *)message
                   withCompletion:(void(^)(NSString *fileURL, NSError *error)) completion DEPRECATED_ATTRIBUTE;

- (void)getLatestMessageForUser:(NSString *)deviceKeyString
               withMetaDataSync:(BOOL)isMetaDataUpdate
                 withCompletion:(void (^)( ALSyncMessageFeed *syncMessageFeed, NSError *error))completion;

- (void)updateMessageMetadataOfKey:(NSString *)messageKey
                      withMetadata:(NSMutableDictionary *)metadata
                    withCompletion:(void(^)(id jsonResponse, NSError *error))completion;

- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
                     isSearch:(BOOL)flag
               withCompletion:(void (^)(NSMutableArray<ALMessage *> *messages, NSError *error))completion;

- (void)searchMessage:(NSString *)key withCompletion:(void (^)(NSMutableArray<ALMessage *> *messages, NSError *error))completion;

- (void)searchMessageWith:(ALSearchRequest *)request withCompletion:(void (^)(NSMutableArray<ALMessage *> *messages, NSError *error))completion;

- (void)getMessagesWithkeys:(NSMutableArray<NSString *> *)keys
             withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

- (void)deleteMessageForAllWithKey:(NSString *)keyString
                    withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

@end
