//
//  ApplozicClient.m
//  Applozic
//
//  Created by Sunil on 12/03/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALAttachmentService.h"
#import "ALMQTTConversationService.h"
#import "ALPushNotificationService.h"
#import "ALRegisterUserClientService.h"
#import "ApplozicClient.h"

@implementation ApplozicClient {
    ALMQTTConversationService *MQTTConversationService;
    ALAttachmentService *attachmentService;
    ALPushNotificationService *pushNotificationService;
}

NSString *const ApplozicClientDomain = @"ApplozicClient";

#pragma mark - Init with AppId

- (instancetype)initWithApplicationKey:(NSString *)appId {
    self = [super init];
    if (self) {
        [ALUserDefaultsHandler setApplicationKey:appId];
        [self setUpServices];
    }
    return self;
}

#pragma mark - Init with AppId and delegate

- (instancetype)initWithApplicationKey:(NSString *)appId withDelegate:(id<ApplozicUpdatesDelegate>)delegate {
    self = [super init];
    if (self) {
        [ALUserDefaultsHandler setApplicationKey:appId];
        pushNotificationService = [[ALPushNotificationService alloc] init];
        self.delegate = delegate;
        pushNotificationService.realTimeUpdate = delegate;
        MQTTConversationService = [ALMQTTConversationService sharedInstance];
        MQTTConversationService.realTimeUpdate = delegate;
        [self setUpServices];
    }
    return self;
}

- (void)setUpServices {

    //TO-DO move this call later to a differnt method
    [ALApplozicSettings setupSuiteAndMigrate];

    _messageService = [ALMessageService sharedInstance];
    _messageService.delegate = self.delegate;
    _messageDbService = [ALMessageDBService new];
    _userService = [ALUserService sharedInstance];
    _channelService = [ALChannelService sharedInstance];
    attachmentService = [ALAttachmentService sharedInstance];
}

#pragma mark - Login

- (void)loginUser:(ALUser *)user withCompletion:(void(^)(ALRegistrationResponse *registrationResponse, NSError *error))completion {

    if (![ALUserDefaultsHandler getApplicationKey]) {
        NSError *applicationKeyNilError = [NSError errorWithDomain:ApplozicClientDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Passed AppID or ApplicationKey is nil."}];
        completion(nil, applicationKeyNilError);
        return;
    } else if (!user) {
        NSError *userNilError = [NSError errorWithDomain:ApplozicClientDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Passed ALUser object is nil."}];
        completion(nil, userNilError);
        return;
    } else if (!user.userId) {
        NSError *userIdNilError = [NSError errorWithDomain:ApplozicClientDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Passed userId is nil,"}];
        completion(nil, userIdNilError);
        return;
    }

    [user setApplicationId:[ALUserDefaultsHandler getApplicationKey]];

    NSString *appModuleName = [ALUserDefaultsHandler getAppModuleName];

    if (appModuleName) {
        [user setAppModuleName:appModuleName];
    } else if (user.appModuleName != NULL) {
        [ALUserDefaultsHandler setAppModuleName:user.appModuleName];
    }

    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService initWithCompletion:user withCompletion:^(ALRegistrationResponse *response, NSError *error) {

        if (error) {
            NSLog(@"Error in User registration: %@", error.description);
            completion(nil, error);
            return;
        }
        
        NSLog(@"User registration response: %@", response);

        if (![response isRegisteredSuccessfully]) {
            NSError *passError = [NSError errorWithDomain:ApplozicClientDomain code:0 userInfo:@{NSLocalizedDescriptionKey : response.message}];
            completion(nil, passError);
            return;
        }
        completion(response, error);
    }];
}


#pragma mark - Logout

- (void)logoutUserWithCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];

    if ([ALUserDefaultsHandler getDeviceKeyString]) {
        [registerUserClientService logoutWithCompletionHandler:^(ALAPIResponse *response, NSError *error) {
            completion(error, response);
        }];
    }
}


#pragma mark - Update APN's device token to applozic

- (void)updateApnDeviceTokenWithCompletion:(NSString *)apnDeviceToken
                            withCompletion:(void(^)(ALRegistrationResponse *registrationResponse, NSError *error))completion {
    if (![ALUserDefaultsHandler getApplicationKey]) {
        NSError *applicationKeyNilError = [NSError errorWithDomain:ApplozicClientDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Passed AppID or ApplicationKey is nil."}];
        completion(nil, applicationKeyNilError);
        return;
    } else if (!apnDeviceToken) {
        NSError *apnsTokenError = [NSError errorWithDomain:ApplozicClientDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"APNs device token is nil."}];
        completion(nil, apnsTokenError);
        return;
    }

    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateApnDeviceTokenWithCompletion:apnDeviceToken withCompletion:^(ALRegistrationResponse *response, NSError *error) {

        if (error) {
            NSLog(@"Update APNs token error: %@",error.description);
            completion(nil, error);
            return;
        }

        if (![response isRegisteredSuccessfully]) {
            NSError *responseError = [NSError errorWithDomain:ApplozicClientDomain
                                                         code:0
                                                     userInfo:@{NSLocalizedDescriptionKey:response.message}];
            completion(nil, responseError);
            return;
        }
        completion(response, error);
    }];

}

#pragma mark - Messages list

- (void)getLatestMessages:(BOOL)isNextPage withCompletionHandler: (void(^)(NSMutableArray *messages, NSError *error)) completion {
    [_messageDbService getLatestMessages:isNextPage withCompletionHandler:^(NSMutableArray *messages, NSError *error) {
        completion(messages, error);
    }];
}


#pragma mark - Message thread

- (void)getMessages:(MessageListRequest *)messageListRequest withCompletionHandler:(void(^)(NSMutableArray *messages, NSError *error)) completion {
    [_messageService getMessageListForUser:messageListRequest
                            withCompletion:^(NSMutableArray *messages, NSError *error, NSMutableArray *userDetailArray) {
        completion(messages, error);
    }];
}



#pragma mark - Converstion read mark group and one to one

- (void)markConversationReadForGroup:(NSNumber *)groupId withCompletion:(void(^)(NSString *response, NSError *error)) completion {

    if (groupId != nil && groupId.integerValue != 0) {
        [_channelService markConversationAsRead:groupId withCompletion:^(NSString *conversationResponse, NSError *error) {
            completion(conversationResponse, error);
        }];
    } else {
        NSError *nilError = [NSError errorWithDomain:ApplozicClientDomain
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey:@"Channel key or groupId is nil."}];

        completion(nil, nilError);
    }
}

- (void)markConversationReadForOnetoOne:(NSString *)userId withCompletion:(void(^)(NSString *response, NSError *error)) completion {

    if (userId) {
        [_userService markConversationAsRead:userId withCompletion:^(NSString *conversationResponse, NSError *error) {
            completion(conversationResponse, error);
        }];
    }  else {
        NSError *nilError = [NSError errorWithDomain:ApplozicClientDomain
                                                code:0
                                            userInfo:@{NSLocalizedDescriptionKey:@"Failed to mark as read userId is nil."}];

        completion(nil, nilError);
    }
}

#pragma mark - Send text message

- (void)sendTextMessage:(ALMessage *)message withCompletion:(void(^)(ALMessage *message, NSError *error))completion {

    if (!message) {
        NSError *messageError = [NSError errorWithDomain:ApplozicClientDomain
                                                    code:MessageNotPresent
                                                userInfo:@{NSLocalizedDescriptionKey : @"Empty message passed."}];

        completion(nil, messageError);
        return;
    }

    if (!message.message) {
        NSError *messageTextError = [NSError errorWithDomain:ApplozicClientDomain
                                                        code:MessageNotPresent
                                                    userInfo:@{NSLocalizedDescriptionKey : @"Passed nil message text in ALMessage object."}];

        completion(nil, messageTextError);
        return;
    }

    [_messageService sendMessages:message withCompletion:^(NSString *jsonResponse, NSError *error) {

        if (error) {
            NSLog(@"Error while sending a message: %@",error.description);
            completion(nil, error);
            return;
        }

        if (self.delegate) {
            [self.delegate onMessageSent:message];
        }
        completion(message, error);
    }];

}

#pragma mark - Send Attachment message

- (void)sendMessageWithAttachment:(ALMessage *)message {
    
    if (!message || !message.imageFilePath) {
        NSLog(@"Failed to send attachment the message or imageFilePath it passed as nil.");
        return;
    }

    [attachmentService sendMessageWithAttachment:message
                                    withDelegate:self.delegate
                          withAttachmentDelegate:self.attachmentProgressDelegate];
}

#pragma mark - Download Attachment message

- (void)downloadMessageAttachment:(ALMessage *)message {
    if (!message) {
        NSLog(@"Failed to download attachment the message passed as nil.");
        return;
    }
    [attachmentService downloadMessageAttachment:message withDelegate:self.attachmentProgressDelegate];
}

- (void)downloadThumbnailImage:(ALMessage *)message {
    if (!message) {
        NSLog(@"Failed to download Thumbnail Image the message passed as nil.");
        return;
    }
    [attachmentService downloadImageThumbnail:message withDelegate:self.attachmentProgressDelegate];
}

#pragma mark - Channel or Group methods

- (void)createChannelWithChannelInfo:(ALChannelInfo *)channelInfo
                      withCompletion:(void(^)(ALChannelCreateResponse *response, NSError *error))completion {

    [_channelService createChannelWithChannelInfo:channelInfo
                                   withCompletion:^(ALChannelCreateResponse *response, NSError *error) {
        completion(response, error);
    }];
}

- (void)removeMemberFromChannelWithUserId:(NSString *)userId
                            andChannelKey:(NSNumber *)channelKey
                       orClientChannelKey:(NSString *)clientChannelKey
                           withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    [_channelService removeMemberFromChannel:userId
                               andChannelKey:channelKey
                          orClientChannelKey:clientChannelKey
                              withCompletion:^(NSError *error, ALAPIResponse *response) {
        completion(error, response);
    }];
}

- (void)leaveMemberFromChannelWithUserId:(NSString *)userId
                           andChannelKey:(NSNumber *)channelKey
                      orClientChannelKey:(NSString *)clientChannelKey
                          withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    [_channelService leaveChannelWithChannelKey:channelKey
                                      andUserId:userId
                             orClientChannelKey:clientChannelKey
                                 withCompletion:^(NSError *error, ALAPIResponse *response) {
        completion(error, response);
    }];

}

- (void)addMemberToChannelWithUserId:(NSString *)userId
                       andChannelKey:(NSNumber *)channelKey
                  orClientChannelKey:(NSString *)clientChannelKey
                      withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    [_channelService addMemberToChannel:userId
                          andChannelKey:channelKey
                     orClientChannelKey:clientChannelKey
                         withCompletion:^(NSError *error, ALAPIResponse *response) {
        completion(error, response);
    }];

}

- (void)updateChannelWithChannelKey:(NSNumber *)channelKey
                         andNewName:(NSString *)newName
                        andImageURL:(NSString *)imageURL
                 orClientChannelKey:(NSString *)clientChannelKey
                 isUpdatingMetaData:(BOOL)flag
                           metadata:(NSMutableDictionary *)metaData
                     orChannelUsers:(NSMutableArray *)channelUsers
                     withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    [_channelService updateChannelWithChannelKey:channelKey
                                      andNewName:newName
                                     andImageURL:imageURL
                              orClientChannelKey:clientChannelKey
                              isUpdatingMetaData:flag
                                        metadata:metaData
                                     orChildKeys:nil
                                  orChannelUsers:channelUsers
                                  withCompletion:^(NSError *error, ALAPIResponse *response) {
        completion(error, response);
    }];

}

- (void)getChannelInformationWithChannelKey:(NSNumber *)channelKey
                         orClientChannelKey:(NSString *)clientChannelKey
                             withCompletion:(void(^)(NSError *error, ALChannel *channel, ALChannelFeedResponse *channelResponse))completion {

    [_channelService getChannelInformationByResponse:channelKey
                                  orClientChannelKey:clientChannelKey
                                      withCompletion:^(NSError *error, ALChannel *channel, ALChannelFeedResponse *channelResponse) {
        completion(error, channel, channelResponse);
    }];

}

#pragma mark - User block

- (void)blockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userBlock))completion {

    [_userService blockUser:userId withCompletionHandler:^(NSError *error, BOOL userBlock) {
        completion(error, userBlock);
    }];
}

#pragma mark - User unblock

- (void)unBlockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userUnblock))completion {

    [_userService unblockUser:userId withCompletionHandler:^(NSError *error, BOOL userUnblock) {
        completion(error, userUnblock);
    }];
}

#pragma mark - Mute or Unmute Channel

- (void)muteChannelOrUnMuteWithChannelKey:(NSNumber *)channelKey
                                  andTime:(NSNumber *)notificationTime
                           withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {

    ALMuteRequest *muteRequest = [ALMuteRequest new];
    muteRequest.id = channelKey;
    muteRequest.notificationAfterTime = notificationTime;

    [_channelService muteChannel:muteRequest withCompletion:^(ALAPIResponse *response, NSError *error) {
        completion(response, error);
    }];

}

#pragma mark - APN's notification process

- (void)notificationArrivedToApplication:(UIApplication *)application withDictionary:(NSDictionary *)userInfo {

    if (pushNotificationService) {
        [pushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
    }
}

#pragma mark - Subscribe To Conversation for real time updates

- (void)subscribeToConversation {
    if (MQTTConversationService) {
        [MQTTConversationService subscribeToConversation];
    }
}

#pragma mark - Unsubscribe To Conversation from real time updates

- (void)unsubscribeToConversation {
    if (MQTTConversationService) {
        [MQTTConversationService unsubscribeToConversation];
    }
}

#pragma mark - Subscribe To typing status for one to one chat

- (void)subscribeToTypingStatusForOneToOne {
    if (MQTTConversationService) {
        [MQTTConversationService subscribeToChannelConversation:nil];
    }
}

#pragma mark - Subscribe To typing status for Channel or Group chat

- (void)subscribeToTypingStatusForChannel:(NSNumber *)channelKey {
    if (MQTTConversationService) {
        [MQTTConversationService subscribeToChannelConversation:channelKey];
    }
}

#pragma mark - Unsubscribe To typing status events for one to one

- (void)unSubscribeToTypingStatusForOneToOne {
    if (MQTTConversationService) {
        [MQTTConversationService unSubscribeToChannelConversation:nil];
    }
}

#pragma mark - Unsubscribe To typing status events for Channel or Group

- (void)unSubscribeToTypingStatusForChannel:(NSNumber *)channelKey {
    if (MQTTConversationService) {
        [MQTTConversationService unSubscribeToChannelConversation:channelKey];
    }
}

- (void)sendTypingStatusForChannelKey:(NSNumber *)channelKey
                           withTyping:(BOOL)isTyping {
    if (MQTTConversationService) {
        [MQTTConversationService sendTypingStatus:nil userID:nil andChannelKey:channelKey typing:isTyping];
    }
}

- (void)sendTypingStatusForUserId:(NSString *)userId withTyping:(BOOL)isTyping {
    if (MQTTConversationService) {
        [MQTTConversationService sendTypingStatus:nil userID:userId andChannelKey:nil typing:isTyping];
    }
}

#pragma mark - Send typing status event for one to one or Channel or Group chat

- (void)sendTypingStatusForUserId:(NSString *)userId orForGroupId:(NSNumber *)channelKey withTyping:(BOOL)isTyping {
    if (channelKey != nil) {
        [self sendTypingStatusForChannelKey:channelKey withTyping:isTyping];
    } else if (userId) {
        [self sendTypingStatusForUserId:userId withTyping:isTyping];
    }
}

#pragma mark - Message list for one to one or Channel or Group

- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler:(void(^)(NSMutableArray *messages, NSError *error)) completion {

    [_messageService getLatestMessages:isNextPage withOnlyGroups:isGroup withCompletionHandler:^(NSMutableArray *messages, NSError *error) {
        completion(messages, error);
    }];
}

@end
