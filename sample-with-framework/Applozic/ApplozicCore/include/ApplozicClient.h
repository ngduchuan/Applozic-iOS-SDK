//
//  ApplozicClient.h
//  Applozic
//
//  Created by Sunil on 12/03/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessageService.h"
#import "ALMessageDBService.h"
#import "ALUserService.h"
#import "ALChannelService.h"
#import "ALRegistrationResponse.h"
#import "ALUser.h"

/// ApplozicClient some of the error types
typedef NS_ENUM(NSInteger, ApplozicClientError) {
    MessageNotPresent = 1
};

/// This protocol is used for listening attachment upload or download events.
@protocol ApplozicAttachmentDelegate <NSObject>

/// This delegate callback will be called on bytes downloaded in attachment with message object.
/// @param bytesReceived It will have total bytes received so far.
/// @param alMessage It will have a message which can be used for identifying which attachment is currently downloading using the message key.
- (void)onUpdateBytesDownloaded:(int64_t)bytesReceived withMessage:(ALMessage *)alMessage;

/// This delegate callback will be called on the progress of uploading bytes.
/// @param bytesSent Bytes uploaded to the server so far.
/// @param alMessage It will have `ALMessage` which can be used for identifying which attachment is currently uploading using message Key.
- (void)onUpdateBytesUploaded:(int64_t)bytesSent withMessage:(ALMessage *)alMessage;

/// This delegate callback will be called once the attachment upload is failed.
/// @param alMessage It will have a message which can be used for identifying which attachment is failed for uploading using the message key.
- (void)onUploadFailed:(ALMessage *)alMessage;

/// This delegate callback will be called once the download failed.
/// @param alMessage It will have a message which can be used for identifying which attachment is currently downloading using the message key.
- (void)onDownloadFailed:(ALMessage *)alMessage;

/// This delegate callback will be called once the uploading is completed.
/// @param alMessage It will have a message which will have updated details like message key and file meta.
/// @param oldMessageKey The old message key is used to identify the message in view for replacing the uploaded attachment `ALMessage`.
- (void)onUploadCompleted:(ALMessage *)alMessage withOldMessageKey:(NSString *)oldMessageKey;

/// This delegate callback will be called once the downloading is completed.
/// @param alMessage It will have `ALMessage`.
- (void)onDownloadCompleted:(ALMessage *)alMessage;

@optional

@end

/// `ApplozicClient` class used for building the custom UI.
@interface ApplozicClient : NSObject  <NSURLConnectionDataDelegate>

/// Use `ApplozicAttachmentDelegate` for real time updates of attachment upload or download status.
@property (nonatomic, strong) id<ApplozicAttachmentDelegate>attachmentProgressDelegate;

/// Instance method of `ALMessageService` object.
@property (nonatomic, retain) ALMessageService *messageService;

/// Instance method of `ALMessageDBService` object.
@property (nonatomic, retain) ALMessageDBService *messageDbService;

/// Instance method of `ALUserService` object.
@property (nonatomic, retain) ALUserService *userService;

/// Instance method of `ALChannelService` object.
@property (nonatomic, retain) ALChannelService *channelService;

/// `ApplozicUpdatesDelegate` is for real-time update events for Messages, Channel, User, Typing.
/// @warning The `ApplozicUpdatesDelegate` is set from `initWithApplicationKey:withDelegate` method only.
@property (nonatomic, weak) id<ApplozicUpdatesDelegate> delegate;

/// Get an Applozic client for given Application Key or App-ID.
///
///
/// You need to login to [console](https://console.applozic.com/login) to get your own Application Key or APP-ID of Applozic.
/// @param applicationKey The unique identifier of application key or APP-ID that is got from applozic.com console.
///
/// Example : Get Applozic client using below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
/// @endcode
- (instancetype)initWithApplicationKey:(NSString *)applicationKey;

/// Get an Applozic client for given Application Key or App-ID  and set the real-time updates events delegate for applozic.
///
///
/// You need to login to [console](https://console.applozic.com/login) to get your own Application Key or APP-ID of Applozic.
/// @param applicationKey The unique identifier of application key or APP-ID that is got from applozic.com console.
/// @param delegate A delegate for real-time update event callbacks.
///
/// Example : Get Applozic client using below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID" withDelegate:self];; // Pass App ID and set the delegate.
/// @endcode
- (instancetype)initWithApplicationKey:(NSString *)applicationKey withDelegate:(id<ApplozicUpdatesDelegate>)delegate;

/// Login a user to Applozic server.
///
///
/// @param alUser An `ALUser` object details for identifying user on server.
/// @param completion An `ALRegistrationResponse` describing an success login or An error describing the authentication failure.
///
///
/// Example : To Login an user to applozic server use the below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
/// ALUser *user = [[ALUser alloc] init];
/// user.userId = @"USER-ID"; // NOTE : +,*,? are not allowed chars in userId.
/// user.password = @"USER-PASSWORD"; // User password
/// user.displayName = @"USER-DISPLAY-NAME"; // User's Display Name
/// user.imageLink = @""; // Pass Profile image URL link
/// user.authenticationTypeId = APPLOZIC; // Authentication type id default is APPLOZIC
/// [ALUserDefaultsHandler setUserAuthenticationTypeId:user.authenticationTypeId];
///
/// [applozicClient loginUser:user withCompletion:^(ALRegistrationResponse *response, NSError *error) {
///
///    if (!error) {
///       NSLog(@"Login success");
///    }
/// }];
/// @endcode
- (void)loginUser:(ALUser *)alUser withCompletion:(void(^)(ALRegistrationResponse *rResponse, NSError *error))completion;

/// Updates an APNs device token to Applozic server.
///
///
/// @param apnDeviceToken An device token which is required for sending for APNs push notification to iPhone device.
/// @param completion An `ALRegistrationResponse` describing an successful update of token otherwise an error describing the update APNs token failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
/// [applozicClient updateApnDeviceTokenWithCompletion:apnDeviceToken
///                                    withCompletion:^(ALRegistrationResponse *rResponse, NSError *error) {
///
///    if (error) {
///        NSLog(@"Failed to update APNs token to applozic server due to: %@",error.localizedDescription);
///        return;
///    }
/// }];
/// @endcode
- (void)updateApnDeviceTokenWithCompletion:(NSString *)apnDeviceToken
                            withCompletion:(void(^)(ALRegistrationResponse *rResponse, NSError *error))completion;

/// Sending an attachment message in one-to-one or channel conversation.
///
///
/// @param attachmentMessage An `ALMessage` object for sending an attachment can be build using `ALMessageBuilder`.
///
/// Example : Sending an attachment message in one-to-one conversation:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
/// applozicClient.attachmentProgressDelegate = self;
///
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder *alMessageBuilder) {
///     alMessageBuilder.to = @"USERI-ID"; // Pass Receiver userId to whom you want to send a message.
///     alMessageBuilder.imageFilePath = @"NAME-OF-FILE"; // File name
///     alMessageBuilder.contentType = ALMESSAGE_CONTENT_ATTACHMENT;
/// }];
///
/// [applozicClient sendMessageWithAttachment:alMessage];
///
/// @endcode
///
/// Example: Sending an attachment message in channel conversation:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
/// applozicClient.attachmentProgressDelegate = self;
///
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
///    alMessageBuilder.groupId = CHANNEL-KEY; // Pass channelKey to channel/group you want to send a attchment message
///    alMessageBuilder.imageFilePath = @"NAME-OF-FILE"; // File name
///    alMessageBuilder.contentType = ALMESSAGE_CONTENT_ATTACHMENT;
/// }];
///
/// [applozicClient sendMessageWithAttachment:alMessage];
/// @endcode
- (void)sendMessageWithAttachment:(ALMessage *)attachmentMessage;

/// Sending a text message in one-to-one or channel conversation.
///
///
/// @param alMessage Message object for sending an attachment message can be build using `ALMessageBuilder`.
/// @param completion On Message sent successfully it will have `ALMessage` object with updated messagekey or an error describing the send message failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
/// applozicClient.attachmentProgressDelegate = self;
///
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder *alMessageBuilder) {
///     alMessageBuilder.to = @"USER-ID"; // Pass userId to whom you want to send a message.
///     alMessageBuilder.message = @"MESSAGE-TEXT"; // Pass message text here.
/// }];
///
/// [applozicClient sendTextMessage:alMessage withCompletion:^(ALMessage *message, NSError *error) {
///  if (!error) {
///    NSLog(@"Update the UI message is sent to server");
///  }
/// }];
///
/// @endcode
- (void)sendTextMessage:(ALMessage *)alMessage withCompletion:(void(^)(ALMessage *message, NSError *error))completion;

/// Fetching the list most recent message of all conversations.
///
///
/// @param isNextPage NO to load the all the recent messages otherwise in case of YES to fetch the next set of older messages.
/// @param completion An array of `ALMessage` objects otherwise an error describing the recent message list failure.
///
/// @code
/// @import ApplozicCore;
///
/// BOOL loadNextPage = NO; // Pass YES in case of loading next set of old conversations.
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
/// [applozicClient getLatestMessages:loadNextPage withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
///   if (error) {
///        NSLog(@"Error in fetching all recent conversations %@", error.localizedDescription);
///        return;
///    }
///
///    for (ALMessage *message in messageList) {
///        NSLog(@"Message object :%@", [message dictionary]);
///    }
/// }];
/// @endcode
- (void)getLatestMessages:(BOOL)isNextPage withCompletionHandler:(void(^)(NSMutableArray *messageList, NSError *error))completion;

/// Fetching one-to-one or channel conversation messages.
///
///
/// @param messageListRequest `MessageListRequest` in case of one-to-one pass the userId or channelKey in case of a channel.
/// @param completion If messages are fetched successfully it will have a list of `ALMessage` objects otherwise an error describing the conversation messages failure.
- (void)getMessages:(MessageListRequest *)messageListRequest withCompletionHandler:(void(^)(NSMutableArray *messageList, NSError *error))completion;

/// Download an attachment message in conversation.
///
///
/// @param alMessage An `ALMessage` object for which downloading an attachement in one-to-one or channel conversation.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
/// applozicClient.attachmentProgressDelegate = self;
///
/// [applozicClient downloadMessageAttachment:alMessage]; // Pass message object to download.
/// @endcode
- (void)downloadMessageAttachment:(ALMessage *)alMessage;

/// Creating a new channel conversation.
///
///
/// Below are the types of the channel's:
/// PRIVATE = 1,
/// PUBLIC = 2,
/// BROADCAST = 5,
/// OPEN = 6,
/// GROUP_OF_TWO = 7
/// @param channelInfo Pass information about channel details.
/// @param completion It will be having complete deatils about channel and status, if its error or success else it will have NSError.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// // Channel members
/// NSMutableArray *chanelMemberArray = [[NSMutableArray alloc] init];
///
/// [chanelMemberArray addObject:@"MemberUserId1"];
/// [chanelMemberArray addObject:@"MemberUserId2"];
///
/// // Channel metadata
/// NSMutableDictionary *channelMetadata = [[NSMutableDictionary alloc] init];
///
/// // Channel info
/// ALChannelInfo *channelInfo = [[ALChannelInfo alloc] init];
/// channelInfo.groupName = @"<CHANNEL-NAME>";
/// channelInfo.imageUrl = @""; // Channel Image URL.
/// channelInfo.groupMemberList = chanelMemberArray;
/// channelInfo.metadata = channelMetadata;
/// channelInfo.type = PUBLIC;
///
/// [applozicClient createChannelWithChannelInfo:channelInfo withCompletion:^(ALChannelCreateResponse *response, NSError *error) {
///
///    if (error) {
///        NSLog(@"Error in creating a channel : %@", error.localizedDescription);
///        return;
///    }
///
///    if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///        NSLog(@"Failed to create channel");
///        return;
///    }
///
///    ALChannel *channel = response.alChannel;
///    NSLog(@"Channel has been created successfully object :%@",[channel dictionary]);
///
/// }];
///
/// @endcode
- (void)createChannelWithChannelInfo:(ALChannelInfo *)channelInfo withCompletion:(void(^)(ALChannelCreateResponse *response, NSError *error))completion;

/// Removing a member from the channel conversation.
///
///
/// @param userId UserId of user that you wanted to remove from channel conversation.
/// @param channelKey An channel Key from the `ALChannel` object that wants to remove a member.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the remove member failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient removeMemberFromChannelWithUserId:@"RecieverUserId"
///                                  andChannelKey:channelKey
///                             orClientChannelKey:clientChannelKey
///                                withCompletion:^(NSError *error, ALAPIResponse *response) {
///
///  if (error) {
///     NSLog(@"Error in removing a member : %@", error.localizedDescription);
///     return;
///   }
///
///  if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///     NSLog(@"Failed to remove the member from channel");
///     return;
///  }
///
/// NSLog(@"Successfully Member has been removed from channel");
///
/// }];
/// @endcode
- (void)removeMemberFromChannelWithUserId:(NSString *)userId
                            andChannelKey:(NSNumber *)channelKey
                       orClientChannelKey:(NSString *)clientChannelKey
                           withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/// Leave member from the channel conversation.
///
///
/// @param userId Currently logged-in userId in applozic for leaving from channel.
/// @param channelKey An Channel key which can be accessed from `ALChannel` object key.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the leave member failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient leaveMemberFromChannelWithUserId:[ALUserDefaultsHandler getUserId]
///                                 andChannelKey:channelKey
///                            orClientChannelKey:clientChannelKey
///                               withCompletion:^(NSError *error, ALAPIResponse *response) {
///
///  if (error) {
///      NSLog(@"Error in leave a member : %@", error.localizedDescription);
///      return;
///  }
///
///  if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///     NSLog(@"Failed to leave a member : %@", response.status);
///     return;
///  }
///  NSLog(@"User left successfully from channel.");
/// }];
/// @endcode
- (void)leaveMemberFromChannelWithUserId:(NSString *)userId
                           andChannelKey:(NSNumber *)channelKey
                      orClientChannelKey:(NSString *)clientChannelKey
                          withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/// Add member to the channel conversation.
///
///
/// @param userId Receiver userId that you want add in the channel.
/// @param channelKey An Channel key which can be accessed from `ALChannel` object key.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the add member to channel failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient addMemberToChannelWithUserId:@"RecieverUserId"
///                             andChannelKey:channelKey
///                        orClientChannelKey:clientChannelKey
///                            withCompletion:^(NSError *error, ALAPIResponse *response) {
///
/// if (error) {
///     NSLog(@"Error in add member in channel :%@", error.localizedDescription);
///     return;
///  }
///
/// if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///     NSLog(@"Failed to add member in channel :%@", response.status);
///     return;
///  }
///
///   NSLog(@"User added successfully.");
///
/// }];
/// @endcode
- (void)addMemberToChannelWithUserId:(NSString *)userId
                       andChannelKey:(NSNumber *)channelKey
                  orClientChannelKey:(NSString *)clientChannelKey
                      withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/// Update's channel information.
///
///
/// @param channelKey An Channel key which can be accessed from `ALChannel` object key.
/// @param newName Name of the channel.
/// @param imageURL Channel Profile image URL.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param flag YES for updating channel metadata Otherwise NO.
/// @param metaData Extra information that can be passed in channel and can access it later when it's required.
/// @param channelUsers To update channel users roles like admin, member the object can be created using class `ALChannelUser`.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the update channel failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// // Channel member roles
/// ALChannelUser *channelUser = [[ALChannelUser alloc] init];
/// channelUser.userId = @"MemberUserId1";
/// channelUser.role = [NSNumber numberWithInt:ADMIN];
///
/// NSMutableArray *channelMemberRoleArray = [[NSMutableArray alloc] init];
/// [channelMemberRoleArray addObject:channelUser];
///
/// [applozicClient updateChannelWithChannelKey:CHANNEL-KEY
///                                 andNewName:@"<CHANNEL-NAME>"
///                                andImageURL:@"<IMAGE-URL>"
///                         orClientChannelKey:@"<CHANNEL-CLIENT-KEY>"
///                         isUpdatingMetaData:NO
///                                   metadata:metadata
///                             orChannelUsers:channelMemberRoleArray
///                             withCompletion:^(NSError *error, ALAPIResponse *response) {
///    if (error) {
///        NSLog(@"Error in channel update : %@", error.localizedDescription);
///        return;
///    }
///
///    if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///        NSLog(@"Failed to update channel : %@", response.status);
///        return;
///    }
///
///   NSLog(@"Updated channel successfully.");
///
/// }];
/// @endcode
- (void)updateChannelWithChannelKey:(NSNumber *)channelKey
                         andNewName:(NSString *)newName
                        andImageURL:(NSString *)imageURL
                 orClientChannelKey:(NSString *)clientChannelKey
                 isUpdatingMetaData:(BOOL)flag
                           metadata:(NSMutableDictionary *)metaData
                     orChannelUsers:(NSMutableArray *)channelUsers
                     withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/// Fetching an channel information.
///
///
/// @param channelKey An channel Key of the channel.
/// @param clientChannelKey Own Channel client key which you can link with your server otherwise nil.
/// @param completion An error describing the channel information failure otherwise an `ALChannel` object will have information of channel.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient getChannelInformationWithChannelKey:channelKey
///                              orClientChannelKey:channelClientKey
///                                     withCompletion:^(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse) {
///
///    if (error) {
///        NSLog(@"Error in fetching a channel :%@", error.localizedDescription);
///        return;
///    }
///
///    if (alChannel) {
///        NSLog(@"Channel object is :%@", [alChannel dictionary]);
///    }
///
/// }];
///@endcode
- (void)getChannelInformationWithChannelKey:(NSNumber *)channelKey
                         orClientChannelKey:(NSString *)clientChannelKey
                             withCompletion:(void(^)(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse))completion;

/// Logout the user from Applozic.
///
///
/// @param completion An `ALAPIResponse` will be having a complete response like status otherwise an error describing the logout failure.
/// @note Logout user will clear local stored data of login user.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient logoutUserWithCompletion:^(NSError *error, ALAPIResponse *response) {
///
/// }];
/// @endcode
- (void)logoutUserWithCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/// Mute or unmute a channel notifications for given channel key and time stamp.
///
///
/// @param channelKey An channel Key of the channel.
/// @param notificationTime Time stamp in milliseconds to mute or unmute channel.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the mute channel failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient muteChannelOrUnMuteWithChannelKey:channelKey
///                                          andTime:notificationTime
///                                   withCompletion:^(ALAPIResponse *response, NSError *error) {
///
///    if (error) {
///        NSLog(@"Failed to mute or unmute the channel got some error : %@",error.localizedDescription);
///        return;
///    }
///
///    if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
///        NSLog(@"Channel muted or unmute successful");
///    }
/// }];
/// @endcode
- (void)muteChannelOrUnMuteWithChannelKey:(NSNumber *)channelKey
                                  andTime:(NSNumber *)notificationTime
                           withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

/// Unblocks the user from receiving messages and other updates related to the receiver.
///
///
/// @param userId UserId of the receiver user whom you want to unblock.
/// @param completion YES user is unblocked otherwise an error describing the user unblock failure.
///
/// @code
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient unBlockUserWithUserId:receiverUserId withCompletion:^(NSError *error, BOOL userUnblock) {
///
/// if (error) {
///     NSLog(@"Failed to unblock the user got some error : %@",error.localizedDescription);
///     return;
///  }
///
/// }];
/// @endcode
- (void)unBlockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userUnblock))completion;

/// Blocks the user from receiving messages and other updates related to the receiver.
///
///
/// @param userId UserId of the receiver user whom you want to block.
/// @param completion YES user is blocked otherwise an error describing the user block failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient blockUserWithUserId:receiverUserId withCompletion:^(NSError *error, BOOL userBlock) {
///
///    if (error) {
///        NSLog(@"Failed to block the user got some error : %@",error.localizedDescription);
///        return;
///    }
/// }];
/// @endcode
- (void)blockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userBlock))completion;

/// Mark the all the messages of conversation as read in channel for given channelKey.
///
///
/// @param groupId Channel key to mark a all messages of conversation as read.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the conversation read failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"];
///
/// [applozicClient markConversationReadForGroup:CHANNEL-KEY withCompletion:^(NSString *response, NSError *error) {
///
///    if (error) {
///        NSLog(@"Error in conversation read:%@",error);
///        return;
///    }
///
///    NSLog(@"Marked a conversation successfully");
///
/// }];
/// @endcode
- (void)markConversationReadForGroup:(NSNumber *)groupId withCompletion:(void(^)(NSString *response, NSError *error))completion;

/// Mark conversation as read in one-to-one conversation for given receiver userId.
///
///
/// @param userId  Receiver userId of user to mark a conversation as read.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the mark conversation failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient markConversationReadForOnetoOne:@"receiverUserId" withCompletion:^(NSString *response, NSError *error) {
///
///    if (error) {
///        NSLog(@"Error in marking conversation read :%@",error.localizedDescription);
///        return;
///    }
///
///     NSLog(@"Marked a conversation successfully");
///
/// }];
/// @endcode
- (void)markConversationReadForOnetoOne:(NSString *)userId withCompletion:(void(^)(NSString *response, NSError *error))completion;

/// APNs push notification messages proccessing.
///
///
/// @param application UIApplication of the APNs notification delegate.
/// @param userInfo An userInfo notification dictionary.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID" withDelegate:self]; // Pass your APP-ID here and delegate.
///
/// [applozicClient notificationArrivedToApplication:application withDictionary:userInfo];
///
/// @endcode
- (void)notificationArrivedToApplication:(UIApplication *)application withDictionary:(NSDictionary *)userInfo;

/// Subscribe for all real-time update events for conversations.
///
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and delegate.
///
/// [applozicClient subscribeToConversation];
/// @endcode
- (void)subscribeToConversation;

/// Unsubscribe for all real-time update events for conversations.
///
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and delegate.
///
/// [applozicClient unsubscribeToConversation];
/// @endcode
- (void)unsubscribeToConversation;

/// Unsubscribe for typing status events of channel for the given channel key.
///
///
/// @param chanelKey An channel Key from the `ALChannel` object that you want to unsubscribe.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and delegate.
///
/// [applozicClient subscribeToTypingStatusForChannel:@<CHANNEL-KEY>]; // Pass the Channel key of the ALChannel
///
/// @endcode
- (void)unSubscribeToTypingStatusForChannel:(NSNumber *)chanelKey;

/// This method is used for unsubscribing the typing status events from one-to-one conversation.
///
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and delegate.
///
/// [applozicClient unSubscribeToTypingStatusForOneToOne];
///
/// @endcode
- (void)unSubscribeToTypingStatusForOneToOne;

/// Sending an typing status in one-to-one or channel conversation.
///
///
/// @param userId For one-to-one conversation pass the receiver userId otherwise nil.
/// @param channelKey For channel conversation pass the channelKey from `ALChannel` object otherwise nil.
/// @param isTyping YES to start the typing and NO to stop the typing in conversation.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here
///
/// [applozicClient sendTypingStatusForUserId:recieverUserId orForGroupId:channelKey withTyping:typingStarted];
///
/// @endcode
- (void)sendTypingStatusForUserId:(NSString *)userId orForGroupId:(NSNumber *)channelKey withTyping:(BOOL)isTyping;

/// Subscribes real-time typing events for one-to-one conversation.
///
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here
///
/// [applozicClient subscribeToTypingStatusForOneToOne];
/// @endcode
- (void)subscribeToTypingStatusForOneToOne;

/// Subscribes typing events for channel conversation.
///
///
/// @param channelKey An Unique channel key for subscribing real-time typing events.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here
///
/// [applozicClient subscribeToTypingStatusForChannel:channelKey]; // Pass the channel key of the channel conversation.
/// @endcode
- (void)subscribeToTypingStatusForChannel:(NSNumber *)channelKey;

/// Fetching the list most recent message of one-one or channel conversations.
///
///
/// @param isNextPage NO to load the all the recent messages otherwise in case of YES to fetch the next set of older messages.
/// @param isGroup YES will give all channel recent conversations, For NO to get the all one-to-one recent conversations.
/// @param completion Array of messages of type `ALMessage` otherwise an error describing the recent conversations failure.
///
/// @code
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>"]; // Pass your APP-ID here
///
/// BOOL loadNextPage = NO; // Pass YES in case of loading next set of old conversations.
/// BOOL loadGroups = NO; // Pass YES in case of loading group conversations.
///
/// [applozicClient getLatestMessages:loadNextPage withOnlyGroups:loadGroups withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
///     if (error) {
///        NSLog(@"Failed to load the recent conversations :%@",error.localizedDescription);
///        return;
///     }
///
///    for (ALMessage *message in messageList) {
///        NSLog(@"Message object %@",[message dictionary]);
///    }
/// }];
/// @endcode
- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler: (void(^)(NSMutableArray *messageList, NSError *error))completion;

@end
