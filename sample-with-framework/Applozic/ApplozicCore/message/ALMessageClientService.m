//
//  ALMessageClientService.m
//  ChatApp
//
//  Created by devashish on 02/10/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALApplozicSettings.h"
#import "ALChannelService.h"
#import "ALConnectionQueueHandler.h"
#import "ALConstant.h"
#import "ALConversationService.h"
#import "ALDBHandler.h"
#import "ALLogger.h"
#import "ALMessage.h"
#import "ALMessageClientService.h"
#import "ALMessageDBService.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALSearchResultCache.h"
#import "ALSyncMessageFeed.h"
#import "ALUserBlockResponse.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserService.h"
#import "ALUtilityClass.h"
#import "MessageListRequest.h"
#import "NSString+Encode.h"

@implementation ALMessageClientService

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupServices];
    }
    return self;
}

- (void)setupServices {
    self.responseHandler = [[ALResponseHandler alloc] init];
}

- (void)downloadImageUrl:(NSString *)blobKey
          withCompletion:(void(^)(NSString *fileURL, NSError *error)) completion {
    [self getURLRequestForImage:blobKey withCompletion:^(NSMutableURLRequest *urlRequest, NSString *fileUrl) {

        if (!urlRequest
            && !fileUrl) {

            NSError *urlError = [NSError errorWithDomain:@"Applozic"
                                                    code:1
                                                userInfo:@{NSLocalizedDescriptionKey : @"Failed to get the download url"}];

            completion(nil, urlError);
            return;
        }

        if (urlRequest) {
            [self.responseHandler authenticateAndProcessRequest:urlRequest andTag:@"FILE DOWNLOAD URL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

                if (error) {
                    completion(nil, error);
                    return;
                }
                NSString *imageDownloadURL = (NSString *)jsonResponse;
                ALSLog(ALLoggerSeverityInfo, @"Response URL for image or attachment : %@",imageDownloadURL);
                completion(imageDownloadURL, nil);
            }];
        } else {
            completion(fileUrl, nil);
        }
    }];

}

- (void)getURLRequestForImage:(NSString *)blobKey
               withCompletion:(void(^)(NSMutableURLRequest *urlRequest, NSString *fileUrl)) completion {

    NSMutableURLRequest *urlRequest = nil;
    if ([ALApplozicSettings isGoogleCloudServiceEnabled]) {
        NSString *fileURLString = [NSString stringWithFormat:@"%@/files/url",KBASE_FILE_URL];
        NSString *blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        urlRequest = [ALRequestHandler createGETRequestWithUrlString:fileURLString paramString:blobParamString];
        completion(urlRequest, nil);
    } else if ([ALApplozicSettings isS3StorageServiceEnabled]) {
        NSString *fileURLString = [NSString stringWithFormat:@"%@/rest/ws/file/url",KBASE_FILE_URL];
        NSString *blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        urlRequest = [ALRequestHandler createGETRequestWithUrlString:fileURLString paramString:blobParamString];
        completion(urlRequest, nil);
    } else if ([ALApplozicSettings isStorageServiceEnabled]) {
        NSString *fileURLString = [NSString stringWithFormat:@"%@%@%@",KBASE_FILE_URL,AL_IMAGE_DOWNLOAD_ENDPOINT,blobKey];
        completion(nil, fileURLString);
        return;
    } else {
        NSString *fileURLString = [NSString stringWithFormat:@"%@/rest/ws/aws/file/%@",KBASE_FILE_URL,blobKey];
        completion(nil, fileURLString);
        return;
    }
}

- (NSMutableURLRequest *)getURLRequestForThumbnail:(NSString *)blobKey {
    if (blobKey == nil) {
        return nil;
    }
    if ([ALApplozicSettings isGoogleCloudServiceEnabled]) {
        NSString *fileURLString = [NSString stringWithFormat:@"%@/files/url",KBASE_FILE_URL];
        NSString *blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        return [ALRequestHandler createGETRequestWithUrlString:fileURLString paramString:blobParamString];
    } else if ([ALApplozicSettings isS3StorageServiceEnabled]) {
        NSString *fileURLString = [NSString stringWithFormat:@"%@/rest/ws/file/url",KBASE_FILE_URL];
        NSString *blobParamString = [@"" stringByAppendingFormat:@"key=%@",blobKey];
        return [ALRequestHandler createGETRequestWithUrlString:fileURLString paramString:blobParamString];
    }
    return nil;
}

- (void)downloadImageThumbnailUrl:(NSString *)url
                          blobKey:(NSString *)blobKey
                       completion:(void (^)(NSString *imageDownloadURL, NSError *error))completion {
    NSMutableURLRequest *urlRequest = [self getURLRequestForThumbnail:blobKey];
    if (urlRequest) {
        [self.responseHandler authenticateAndProcessRequest:urlRequest
                                                     andTag:@"FILE DOWNLOAD URL"
                                      WithCompletionHandler:^(id jsonResponse, NSError *error) {
            if (error) {
                completion(nil, error);
                return;
            }
            NSString *imageDownloadURL = (NSString *)jsonResponse;
            ALSLog(ALLoggerSeverityInfo, @"Response URL For Thumbnail is : %@", imageDownloadURL);
            completion(imageDownloadURL, nil);
        }];
    } else {
        completion(url, nil);
    }
}

- (void)addWelcomeMessage:(NSNumber *)channelKey {
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc]init];

    ALMessage *message = [ALMessage new];

    message.contactIds = @"applozic";//1
    message.to = @"applozic";//2
    message.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
    message.deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    message.sendToDevice = NO;
    message.shared = NO;
    message.fileMeta = nil;
    message.status = [NSNumber numberWithInt:READ];
    message.key = @"welcome-message-temp-key-string";
    message.delivered=NO;
    message.fileMetaKey = @"";//4
    message.contentType = 0;
    message.status = [NSNumber numberWithInt:DELIVERED_AND_READ];
    if (channelKey!=nil) {
        message.type=@"101";
        message.message=@"You have created a new group, Say something!!";
        message.groupId = channelKey;
    } else {
        message.type = @"4";
        message.message = @"Welcome to Applozic! Drop a message here or contact us at devashish@applozic.com for any queries. Thanks";//3
        message.groupId = nil;
    }
    [messageDBService createMessageEntityForDBInsertionWithMessage:message];
    [databaseHandler saveContext];

}

- (void)getLatestMessageGroupByContact:(NSUInteger)mainPageSize
                             startTime:(NSNumber *)startTime
                        withCompletion:(void(^)(ALMessageList *messageList, NSError *error)) completion {
    ALSLog(ALLoggerSeverityInfo, @"\nGet Latest Messages \t State:- User Login ");

    NSString *messageListURLString = [NSString stringWithFormat:@"%@/rest/ws/message/list",KBASE_URL];

    NSString *messageListParamString = [NSString stringWithFormat:@"startIndex=%@&mainPageSize=%lu&deletedGroupIncluded=%@",
                                        @"0",(unsigned long)mainPageSize,@(YES)];

    if (startTime != nil) {
        messageListParamString = [NSString stringWithFormat:@"startIndex=%@&mainPageSize=%lu&endTime=%@&deletedGroupIncluded=%@",
                                  @"0", (unsigned long)mainPageSize, startTime,@(YES)];
    }
    if ([ALApplozicSettings getCategoryName]) {
        messageListParamString = [messageListParamString stringByAppendingString:[NSString stringWithFormat:@"&category=%@",
                                                                                  [ALApplozicSettings getCategoryName]]];
    }

    NSMutableURLRequest *messageListRequest = [ALRequestHandler createGETRequestWithUrlString:messageListURLString paramString:messageListParamString];

    [self.responseHandler authenticateAndProcessRequest:messageListRequest
                                                 andTag:@"GET MESSAGES GROUP BY CONTACT"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        ALMessageList *messageListResponse = [[ALMessageList alloc] initWithJSONString:jsonResponse];
        ALSLog(ALLoggerSeverityInfo, @"Message list response JSON : %@",jsonResponse);

        if (jsonResponse) {
            [ALUserDefaultsHandler setInitialMessageListCallDone:YES];
            if (messageListResponse.userDetailsList) {
                ALContactDBService *contactDBService = [[ALContactDBService alloc] init];
                [contactDBService addUserDetails:messageListResponse.userDetailsList];
            }
            ALChannelService *channelService = [[ALChannelService alloc] init];
            [channelService callForChannelServiceForDBInsertion:jsonResponse];

            /// Save the last message created time for calling the message list API.
            /// Next time onwards this saved time will be used. as the start time

            if (messageListResponse.messageList.count > 0) {
                ALMessage *lastMessage = (ALMessage *)[messageListResponse.messageList lastObject];
                [ALUserDefaultsHandler setLastMessageListTime:lastMessage.createdAtTime];
            }
        }
        //USER BLOCK SYNC CALL
        ALUserService *userService = [ALUserService new];
        [userService blockUserSync: [ALUserDefaultsHandler getUserBlockLastTimeStamp]];

        completion(messageListResponse, nil);

    }];
}

- (void)getMessagesListGroupByContactswithCompletion:(void(^)(NSMutableArray *messages, NSError *error)) completion {
    ALSLog(ALLoggerSeverityInfo, @"\nGet Latest Messages \t State:- User Opens Message List View");
    NSString *messageListURLString = [NSString stringWithFormat:@"%@/rest/ws/message/list", KBASE_URL];

    NSString *messageListParamString = [NSString stringWithFormat:@"startIndex=%@&deletedGroupIncluded=%@",@"0",@(YES)];

    NSMutableURLRequest *messageListRequest = [ALRequestHandler createGETRequestWithUrlString:messageListURLString paramString:messageListParamString];
    [self.responseHandler authenticateAndProcessRequest:messageListRequest andTag:@"GET MESSAGES GROUP BY CONTACT" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        ALMessageList *messageListResponse = [[ALMessageList alloc] initWithJSONString:jsonResponse];

        ALChannelService *channelService = [[ALChannelService alloc] init];
        [channelService callForChannelServiceForDBInsertion:jsonResponse];
        completion(messageListResponse.messageList , nil);
    }];

}

- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
                withOpenGroup:(BOOL)isOpenGroup
               withCompletion:(void (^)(NSMutableArray *messages, NSError *error, NSMutableArray *userDetails))completion {
    NSString *messageURLString = [NSString stringWithFormat:@"%@/rest/ws/message/list",KBASE_URL];

    NSMutableURLRequest *messageThreadRequest = [ALRequestHandler createGETRequestWithUrlString:messageURLString paramString:messageListRequest.getParamString];

    [self.responseHandler authenticateAndProcessRequest:messageThreadRequest andTag:@"GET MESSAGES LIST FOR USERID" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"MSG_LIST ERROR :: %@",error.description);
            completion(nil, error, nil);
            return;
        }

        if (!(messageListRequest.channelType == OPEN)) {
            if (messageListRequest.channelKey != nil) {
                [ALUserDefaultsHandler setServerCallDoneForMSGList:true forContactId:[messageListRequest.channelKey stringValue]];
            } else {
                [ALUserDefaultsHandler setServerCallDoneForMSGList:true forContactId:messageListRequest.userId];
            }
        }

        if (messageListRequest.conversationId != nil) {
            [ALUserDefaultsHandler setServerCallDoneForMSGList:true forContactId:[messageListRequest.conversationId stringValue]];
        }

        ALMessageList *messageListResponse = [[ALMessageList alloc] initWithJSONString:jsonResponse
                                                                         andWithUserId:messageListRequest.userId
                                                                          andWithGroup:messageListRequest.channelKey];

        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        [messageDBService addMessageList:messageListResponse.messageList skipAddingMessageInDb:isOpenGroup];
        ALConversationService *conversationService = [[ALConversationService alloc] init];
        [conversationService addConversations:messageListResponse.conversationPxyList];

        ALChannelService *channelService = [[ALChannelService alloc] init];
        [channelService callForChannelServiceForDBInsertion:jsonResponse];
        ALSLog(ALLoggerSeverityInfo, @"Message thread response : %@",(NSString *)jsonResponse);
        completion(messageListResponse.messageList, nil, messageListResponse.userDetailsList);
    }];
}

- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
               withCompletion:(void (^)(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray))completion {
    ALChannel *channel = nil;
    if (messageListRequest.channelKey != nil) {
        channel = [[ALChannelService sharedInstance] getChannelByKey:messageListRequest.channelKey];
    }

    [self getMessageListForUser:messageListRequest
                  withOpenGroup:(channel != nil && channel.type == OPEN)
                 withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {

        completion(messages, error, userDetailArray);

    }];
}

- (void)sendPhotoForUserInfo:(NSDictionary *)userInfo withCompletion:(void(^)(NSString *message, NSError *error)) completion {
    if (ALApplozicSettings.isStorageServiceEnabled) {
        NSString *fileUploadURLString = [NSString stringWithFormat:@"%@%@", KBASE_FILE_URL, AL_IMAGE_UPLOAD_ENDPOINT];
        completion(fileUploadURLString, nil);
    } else if (ALApplozicSettings.isS3StorageServiceEnabled) {
        NSString *fileUploadURLString = [NSString stringWithFormat:@"%@%@", KBASE_FILE_URL, AL_CUSTOM_STORAGE_IMAGE_UPLOAD_ENDPOINT];
        completion(fileUploadURLString, nil);
    } else if (ALApplozicSettings.isGoogleCloudServiceEnabled) {
        NSString *fileUploadURLString = [NSString stringWithFormat:@"%@%@", KBASE_FILE_URL, AL_IMAGE_UPLOAD_ENDPOINT];
        completion(fileUploadURLString, nil);
    } else {
        NSString *fileUploadURLString = [NSString stringWithFormat:@"%@/rest/ws/aws/file/url",KBASE_FILE_URL];

        NSMutableURLRequest *fileURLRequest = [ALRequestHandler createGETRequestWithUrlString:fileUploadURLString paramString:nil];

        [self.responseHandler authenticateAndProcessRequest:fileURLRequest andTag:@"CREATE FILE URL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

            if (error) {
                completion(nil, error);
                return;
            }

            NSString *imagePostingURL = (NSString *)error;
            ALSLog(ALLoggerSeverityInfo, @"Upload Image or attachment URL : %@",imagePostingURL);
            completion(imagePostingURL, nil);
        }];
    }
}

- (void) getLatestMessageForUser:(NSString *)deviceKeyString
                  withCompletion:(void (^)(ALSyncMessageFeed *syncMessageFeed, NSError *error))completion {
    [self getLatestMessageForUser:deviceKeyString withMetaDataSync:NO withCompletion:^(ALSyncMessageFeed *syncMessageFeed, NSError *error) {
        completion(syncMessageFeed,error);
    }];
}

- (void)deleteMessage:(NSString *)keyString
         andContactId:(NSString *)contactId
       withCompletion:(void (^)(NSString *response, NSError *error))completion {
    NSString *deleteMessageURLString = [NSString stringWithFormat:@"%@/rest/ws/message/delete",KBASE_URL];
    NSString *deleteMessageParamString = [NSString stringWithFormat:@"key=%@&userId=%@",keyString,[contactId urlEncodeUsingNSUTF8StringEncoding]];
    NSMutableURLRequest *deleteMessageRequest = [ALRequestHandler createGETRequestWithUrlString:deleteMessageURLString paramString:deleteMessageParamString];

    [self.responseHandler authenticateAndProcessRequest:deleteMessageRequest andTag:@"DELETE_MESSAGE" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            completion(nil,error);
            return;
        }

        NSString *status = (NSString *)jsonResponse;
        ALSLog(ALLoggerSeverityInfo, @"Response of delete message: %@", status);
        if ([status isEqualToString:AL_RESPONSE_SUCCESS]) {
            completion(status, nil);
            return;
        } else {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to delete the message due to internal error"}];
            completion(nil, responseError);
            return;
        }
    }];
}

- (void)deleteMessageThread:(NSString *)contactId
               orChannelKey:(NSNumber *)channelKey
             withCompletion:(void (^)(NSString *response, NSError *error))completion {
    NSString *deleteThreadURLString = [NSString stringWithFormat:@"%@/rest/ws/message/delete/conversation",KBASE_URL];
    NSString *deleteThreadParamString;
    if (channelKey != nil) {
        deleteThreadParamString = [NSString stringWithFormat:@"groupId=%@",channelKey];
    } else {
        deleteThreadParamString = [NSString stringWithFormat:@"userId=%@",[contactId urlEncodeUsingNSUTF8StringEncoding]];
    }
    NSMutableURLRequest *deleteThreadRequest = [ALRequestHandler createGETRequestWithUrlString:deleteThreadURLString paramString:deleteThreadParamString];

    [self.responseHandler authenticateAndProcessRequest:deleteThreadRequest andTag:@"DELETE_MESSAGE_THREAD" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in delete message thread: %@", error.description);
            completion(nil, error);
            return;
        }
        NSString *status = (NSString *)jsonResponse;
        ALSLog(ALLoggerSeverityInfo, @"Response of delete message thread: %@", (NSString *)jsonResponse);
        if ([status isEqualToString:AL_RESPONSE_SUCCESS]) {
            ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
            [messageDBService deleteAllMessagesByContact:contactId orChannelKey:channelKey];
            completion(status, nil);
            return;
        } else {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to delete the message thread due to internal error"}];
            completion(nil, responseError);
            return;
        }
    }];

}

- (void)sendMessage:(NSDictionary *)userInfo
withCompletionHandler:(void(^)(id jsonResponse, NSError *error))completion {
    NSString *messageSendURLString = [NSString stringWithFormat:@"%@/rest/ws/message/v2/send",KBASE_URL];
    NSString *messageSendParamString = [ALUtilityClass generateJsonStringFromDictionary:userInfo];

    NSMutableURLRequest *messageSendRequest = [ALRequestHandler createPOSTRequestWithUrlString:messageSendURLString paramString:messageSendParamString];

    [self.responseHandler authenticateAndProcessRequest:messageSendRequest andTag:@"SEND MESSAGE" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            completion(nil,error);
            return;
        }
        completion(jsonResponse,nil);
    }];
}

- (void)getCurrentMessageInformation:(NSString *)messageKey
               withCompletionHandler:(void(^)(ALMessageInfoResponse *messageInfoResponse, NSError *error))completion {
    NSString *messageInfoURLString = [NSString stringWithFormat:@"%@/rest/ws/message/info", KBASE_URL];
    NSString *messageKeyParamString = [NSString stringWithFormat:@"key=%@", messageKey];

    NSMutableURLRequest *messageInfoRequest = [ALRequestHandler createGETRequestWithUrlString:messageInfoURLString paramString:messageKeyParamString];

    [self.responseHandler authenticateAndProcessRequest:messageInfoRequest andTag:@"MESSSAGE_INFORMATION" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in message information API: %@", error);
            completion(nil, error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"Response of Message information API JSON : %@", (NSString *)jsonResponse);
            ALMessageInfoResponse *messageInfoResponse = [[ALMessageInfoResponse alloc] initWithJSONString:(NSString *)jsonResponse];
            completion(messageInfoResponse, error);
        }
    }];
}

- (void)getLatestMessageForUser:(NSString *)deviceKeyString
               withMetaDataSync:(BOOL)isMetaDataUpdate
                 withCompletion:(void (^)(ALSyncMessageFeed *syncMessageFeed, NSError *error))completion {
    if (!deviceKeyString) {
        NSError *deviceKeyNilError = [NSError
                                      errorWithDomain:@"Applozic"
                                      code:1
                                      userInfo:[NSDictionary
                                                dictionaryWithObject:@"Device key is nil"
                                                forKey:NSLocalizedDescriptionKey]];
        completion(nil, deviceKeyNilError);
        return;
    }
    NSString *messageSyncURLString = [NSString stringWithFormat:@"%@/rest/ws/message/sync",KBASE_URL];
    NSString *lastSyncTime;
    NSString *messageSyncParamString;
    if (isMetaDataUpdate) {
        lastSyncTime = [NSString stringWithFormat:@"%@", [ALUserDefaultsHandler getLastSyncTimeForMetaData]];
        messageSyncParamString = [NSString stringWithFormat:@"lastSyncTime=%@&metadataUpdate=true",lastSyncTime];
    } else {
        lastSyncTime = [NSString stringWithFormat:@"%@", [ALUserDefaultsHandler getLastSyncTime]];
        messageSyncParamString = [NSString stringWithFormat:@"lastSyncTime=%@",lastSyncTime];
    }

    ALSLog(ALLoggerSeverityInfo, @"LAST SYNC TIME IN CALL :  %@", lastSyncTime);

    NSMutableURLRequest *messageSyncRequest = [ALRequestHandler createGETRequestWithUrlString:messageSyncURLString paramString:messageSyncParamString];
    [self.responseHandler authenticateAndProcessRequest:messageSyncRequest andTag:@"SYNC LATEST MESSAGE URL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            [ALUserDefaultsHandler setMsgSyncRequired:YES];
            completion(nil,error);
            return;
        }

        [ALUserDefaultsHandler setMsgSyncRequired:NO];
        ALSyncMessageFeed *syncMessageFeed = [[ALSyncMessageFeed alloc] initWithJSONString:jsonResponse];
        ALSLog(ALLoggerSeverityInfo, @"LATEST_MESSAGE_JSON: %@", (NSString *)jsonResponse);
        completion(syncMessageFeed,nil);
    }];
}

- (void)updateMessageMetadataOfKey:(NSString *)messageKey
                      withMetadata:(NSMutableDictionary *)metadata
                    withCompletion:(void (^)(id, NSError *error))completion {
    ALSLog(ALLoggerSeverityInfo, @"Updating message metadata for message : %@", messageKey);
    NSString *metadataURLString = [NSString stringWithFormat:@"%@/rest/ws/message/update/metadata",KBASE_URL];
    NSMutableDictionary *messageMetadata = [NSMutableDictionary new];

    [messageMetadata setObject:messageKey forKey:@"key"];
    [messageMetadata setObject:metadata forKey:@"metadata"];

    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:messageMetadata options:0 error:&error];
    NSString *metadataParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];

    NSMutableURLRequest *metadataUpdateRequest = [ALRequestHandler createPOSTRequestWithUrlString:metadataURLString paramString:metadataParamString];

    [self.responseHandler authenticateAndProcessRequest:metadataUpdateRequest andTag:@"UPDATE_MESSAGE_METADATA" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError,@"Error while updating message metadata: %@", error);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Message metadata updated successfully with result : %@", jsonResponse);
        completion(jsonResponse, nil);
    }];
}

- (void)searchMessage:(NSString *)key
       withCompletion:(void (^)(NSMutableArray<ALMessage *> *messages, NSError *error))completion {
    ALSLog(ALLoggerSeverityInfo, @"Search messages with %@", key);
    NSString *messageSearchURLString = [NSString stringWithFormat:@"%@/rest/ws/group/support", KBASE_URL];
    NSString *messageSearchParamString = [NSString stringWithFormat:@"search=%@", [key urlEncodeUsingNSUTF8StringEncoding]];

    NSMutableURLRequest *messageURLRequest = [ALRequestHandler
                                              createGETRequestWithUrlString: messageSearchURLString
                                              paramString: messageSearchParamString];

    [self.responseHandler
     authenticateAndProcessRequest:messageURLRequest
     andTag: @"Search messages"
     WithCompletionHandler: ^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"Search messages ERROR :: %@",error.description);
            completion(nil, error);
            return;
        }

        if (![[jsonResponse valueForKey:@"status"] isEqualToString:AL_RESPONSE_SUCCESS]) {
            ALSLog(ALLoggerSeverityError, @"Search messages ERROR :: %@",error.description);
            NSError *error = [NSError
                              errorWithDomain:@"Applozic"
                              code:1
                              userInfo:[NSDictionary
                                        dictionaryWithObject:@"Status fail in response"
                                        forKey:NSLocalizedDescriptionKey]];
            completion(nil, error);
            return;
        }

        NSString *response = [jsonResponse valueForKey: @"response"];
        if (response == nil) {
            ALSLog(ALLoggerSeverityError, @"Search messages RESPONSE is nil");
            NSError *error = [NSError errorWithDomain:@"Search response is nil" code:0 userInfo:nil];
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Search messages RESPONSE :: %@", (NSString *)jsonResponse);
        NSMutableArray<ALMessage *> *messages = [NSMutableArray new];
        NSDictionary *messagesDictionary = [response valueForKey: @"message"];
        for (NSDictionary *messageDictionary in messagesDictionary) {
            ALMessage *message = [[ALMessage alloc] initWithDictonary: messageDictionary];
            [messages addObject: message];
        }
        ALChannelFeed *channelFeed = [[ALChannelFeed alloc] initWithJSONString: response];
        [[ALSearchResultCache shared] saveChannels: channelFeed.channelFeedsList];
        completion(messages, nil);
        return;
    }];
}

- (void)searchMessageWith:(ALSearchRequest *)request
           withCompletion:(void (^)(NSMutableArray<ALMessage *> *messages, NSError *error))completion {

    if (!request.searchText || request.searchText.length == 0 ) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary
                                    dictionaryWithObject:@"Search text is empty or nil"
                                    forKey:NSLocalizedDescriptionKey]];
        completion(nil, error);
        return;
    }

    NSString *messageSerarchURLString = [NSString stringWithFormat:@"%@/rest/ws/message/search", KBASE_URL];
    NSString *messageSearchParamString = [request getParamString];

    NSMutableURLRequest *messageURLRequest = [ALRequestHandler
                                              createGETRequestWithUrlString:messageSerarchURLString
                                              paramString: messageSearchParamString];

    [self.responseHandler
     authenticateAndProcessRequest: messageURLRequest
     andTag: @"Search messages"
     WithCompletionHandler: ^(id jsonResponse, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Search messages ERROR :: %@",error.description);
            completion(nil, error);
            return;
        }
        if (![[jsonResponse valueForKey:@"status"] isEqualToString:AL_RESPONSE_SUCCESS]) {
            ALSLog(ALLoggerSeverityError, @"Search messages ERROR :: %@",error.description);
            NSError *error = [NSError
                              errorWithDomain:@"Applozic"
                              code:1
                              userInfo:[NSDictionary
                                        dictionaryWithObject:@"Status fail in response"
                                        forKey:NSLocalizedDescriptionKey]];
            completion(nil, error);
            return;
        }
        NSString *response = [jsonResponse valueForKey: @"response"];
        if (response == nil) {
            ALSLog(ALLoggerSeverityError, @"Search messages RESPONSE is nil");
            NSError *error = [NSError errorWithDomain:@"Search response is nil" code:0 userInfo:nil];
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Search messages RESPONSE :: %@", (NSString *)jsonResponse);
        NSMutableArray<ALMessage *> *messages = [NSMutableArray new];
        NSDictionary *messagesDictionary = [response valueForKey: @"message"];
        for (NSDictionary *messageDictionary in messagesDictionary) {
            ALMessage *message = [[ALMessage alloc] initWithDictonary: messageDictionary];
            [messages addObject: message];
        }
        ALChannelFeed *channelFeed = [[ALChannelFeed alloc] initWithJSONString: response];
        [[ALSearchResultCache shared] saveChannels: channelFeed.channelFeedsList];
        completion(messages, nil);
        return;
    }];
}

- (void)getMessageListForUser:(MessageListRequest *)messageListRequest
                     isSearch:(BOOL)flag
               withCompletion:(void (^)(NSMutableArray<ALMessage *> *messages, NSError *error))completion {
    NSString *messageThreadURLString = [NSString stringWithFormat: @"%@/rest/ws/message/list", KBASE_URL];
    NSMutableURLRequest *messageThreadRequest = [ALRequestHandler
                                                 createGETRequestWithUrlString: messageThreadURLString
                                                 paramString: messageListRequest.getParamString];

    [self.responseHandler authenticateAndProcessRequest:messageThreadRequest andTag:@"Messages for searched conversation" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error while getting messages :: %@", error.description);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Messages fetched succesfully :: %@", (NSString *)jsonResponse);

        NSDictionary *messagesDictionary = [jsonResponse valueForKey:@"message"];
        NSMutableArray<ALMessage *> *messages = [NSMutableArray new];
        for (NSDictionary *messageDictionary in messagesDictionary) {
            ALMessage *message = [[ALMessage alloc] initWithDictonary:messageDictionary];
            [messages addObject: message];
        }

        NSDictionary *userDetailsDictionary = [jsonResponse valueForKey:@"userDetails"];
        NSMutableArray<ALUserDetail *> *userDetails = [NSMutableArray new];
        for (NSDictionary *userDetailDictionary in userDetailsDictionary) {
            ALUserDetail *userDetail = [[ALUserDetail alloc] initWithDictonary: userDetailDictionary];
            [userDetails addObject: userDetail];
        }
        [[ALSearchResultCache shared] saveUserDetails: userDetails];

        ALChannelFeed *channelFeed = [[ALChannelFeed alloc] initWithJSONString:jsonResponse];

        ALConversationService *conversationService = [[ALConversationService alloc] init];
        [conversationService addConversations:channelFeed.conversationProxyList];

        ALChannelService *channelService = [[ALChannelService alloc] init];
        [channelService saveChannelUsersAndChannelDetails:channelFeed.channelFeedsList calledFromMessageList:YES];
        completion(messages, nil);
    }];
}

- (void)getMessagesWithkeys:(NSMutableArray<NSString *> *)keys withCompletion:(void (^)(ALAPIResponse *response, NSError *error))completion {
    NSString *messageInfoURLString = [NSString stringWithFormat:@"%@/rest/ws/message/detail", KBASE_URL];
    NSMutableString *paramMessageKeyString = [[NSMutableString alloc] init];
    for (NSString *key in keys) {
        [paramMessageKeyString appendString: [NSString stringWithFormat:@"keys=%@&", key]];
    }

    if (keys.count > 0) {
        /// We have an extra ampersand.
        [paramMessageKeyString deleteCharactersInRange:NSMakeRange([paramMessageKeyString length] - 1, 1)];
    }
    NSMutableURLRequest *messageInfoRequest = [ALRequestHandler createGETRequestWithUrlString: messageInfoURLString paramString: paramMessageKeyString];

    [self.responseHandler authenticateAndProcessRequest:messageInfoRequest andTag:@"Get hidden messages" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Fetching message error %@", (NSString *)jsonResponse);
            completion(nil, error);
            return;
        }
        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        ALSLog(ALLoggerSeverityInfo, @"Messages fetched successfully %@", (NSString *)jsonResponse);
        completion(response, nil);
    }];
}

- (void)deleteMessageForAllWithKey:(NSString *)keyString
                    withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {
    NSString *deleteAllURLString = [NSString stringWithFormat:@"%@/rest/ws/message/v2/delete",KBASE_URL];
    NSString *deleteAllParamString = [NSString stringWithFormat:@"key=%@&deleteForAll=true", keyString];

    NSMutableURLRequest *deleteAllRequest = [ALRequestHandler createGETRequestWithUrlString:deleteAllURLString paramString:deleteAllParamString];

    [self.responseHandler authenticateAndProcessRequest:deleteAllRequest andTag:@"DELETE_MESSAGE_FOR_ALL" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Response for delete message for all: %@", (NSString *)jsonResponse);
        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
            completion(response, nil);
        } else {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to delete the message for all"}];
            completion(nil, responseError);
        }
    }];
}

@end
