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

/// `ApplozicAttachmentDelegate` protocol is used for listening attachment upload or download events.
@protocol ApplozicAttachmentDelegate <NSObject>

/// Will be called on downloaded bytes in attachment with `ALMessage` object.
/// @param bytesReceived It will have total bytes received so far.
/// @param alMessage It will have a message which can be used for identifying which attachment is currently downloading by using the message key.
- (void)onUpdateBytesDownloaded:(int64_t)bytesReceived withMessage:(ALMessage *)alMessage;

/// Will be called on upload progress of bytes with `ALMessage` object.
/// @param bytesSent Bytes uploaded to the server so far.
/// @param alMessage It will have `ALMessage` which can be used for identifying which attachment is currently uploading by using message Key.
- (void)onUpdateBytesUploaded:(int64_t)bytesSent withMessage:(ALMessage *)alMessage;

/// On attachment upload failed this callback will be called `ALMessage` object.
/// @param alMessage It will have a message which can be used for identifying which attachment is failed for uploading using the message key.
- (void)onUploadFailed:(ALMessage *)alMessage;

/// On attachment download failed this callback will be called with `ALMessage` object.
/// @param alMessage It will have a message which can be used for identifying which attachment is currently downloading using the message key.
- (void)onDownloadFailed:(ALMessage *)alMessage;

/// On uploading is completed this callback will be called with the `ALMessage` object and message key.
/// @param alMessage It will have a message which will have updated details like message key and file meta.
/// @param oldMessageKey The old message key is used to identify the message in view for replacing the uploaded attachment `ALMessage`.
- (void)onUploadCompleted:(ALMessage *)alMessage withOldMessageKey:(NSString *)oldMessageKey;

/// On downloading is completed this callback will be called with the `ALMessage` object.
///
/// On download completed callback you can access the file name from the `ALMessage` object and using the file name you can access the file in the Application documents directory.
///
/// @param alMessage It will have `ALMessage` object.
///
/// @code
/// NSString *fileName = alMessage.imageFilePath;
///
/// NSURL *directory = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:fileName]; // Document URL of the file.
///
/// NSString *filePath = directory.path; // Path to file
/// @endcode
- (void)onDownloadCompleted:(ALMessage *)alMessage;

@optional

@end

/// `ApplozicClient` has major core methods that can be used to build a chat application.
///
/// Available methods that this class has:
///
/// Initialization of APP-ID, Authentication, User, Block, Message, Conversation, Channel/Group, Real-time Events.
/// @note To access any method you need to get `ApplozicClient` object using an method `-[ApplozicClient initWithApplicationKey:]` or `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
@interface ApplozicClient : NSObject <NSURLConnectionDataDelegate>

/// Use `ApplozicAttachmentDelegate` for real time updates of attachment upload or download status.
@property (nonatomic, strong) id<ApplozicAttachmentDelegate>attachmentProgressDelegate;

/// `ALMessageService` instance is used for making API calls related to conversations. Default Instance is created from `-[ApplozicClient initWithApplicationKey:]` or `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
@property (nonatomic, retain) ALMessageService *messageService;

/// `ALMessageDBService` instance is used for storing data releated to `ALMessage`. Default Instance is created from `-[ApplozicClient initWithApplicationKey:]` or `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
@property (nonatomic, retain) ALMessageDBService *messageDbService;

/// `ALUserService` instance is used for making API calls related to `ALUser`. Default Instance is created from `-[ApplozicClient initWithApplicationKey:]` or `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
@property (nonatomic, retain) ALUserService *userService;

/// `ALChannelService` Instance is used for making API calls related to `ALChannel`. Default Instance is created from `-[ApplozicClient initWithApplicationKey:]` or `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
@property (nonatomic, retain) ALChannelService *channelService;

/// `ApplozicUpdatesDelegate` is for real-time update events for Messages, Channel, User, Typing.
/// @warning The `ApplozicUpdatesDelegate` is set from `-[ApplozicClient initWithApplicationKey:withDelegate:]` method only.
@property (nonatomic, weak) id<ApplozicUpdatesDelegate> delegate;

/// Get an `ApplozicClient` for given Application Key or App-ID.
///
///
/// You need to login to [console](https://console.applozic.com/login) to get your Application Key or APP-ID of Applozic.
/// @param applicationKey The unique identifier of application key or APP-ID that is got from applozic.com console.
///
/// Example: Get Applozic client using below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
/// @endcode
- (instancetype)initWithApplicationKey:(NSString *)applicationKey;

/// Get an `ApplozicClient` for given Application Key or App-ID and set the real-time updates events delegate for applozic.
///
///
/// You need to login to [console](https://console.applozic.com/login) to get your Application Key or APP-ID of Applozic.
/// @param applicationKey The unique identifier of application key or APP-ID that is got from applozic.com console.
/// @param delegate A delegate for real-time update events for Messages, Channel, User, Typing.
///
/// Example: Get Applozic client using below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID" withDelegate:self];; // Pass App ID and set the delegate.
/// @endcode
- (instancetype)initWithApplicationKey:(NSString *)applicationKey withDelegate:(id<ApplozicUpdatesDelegate>)delegate;

/// Use this method to log in or register your `ALUser`. This must be done before any other method of the SDK is used.
///
/// @param alUser An `ALUser` object details for identifying the user on the server.
/// @param completion An `ALRegistrationResponse` describing a successful login or An error describing the authentication failure.
///
/// If the user (identified by its userId) is not present in the servers, a new one will be created and registered. Otherwise, the existing user will be authenticated and logged in.
///
/// Example: To log in a user to applozic server use the below code:
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
///     if (!error) {
///        NSLog(@"User Login success");
///     }
///
/// }];
///
/// @endcode
- (void)loginUser:(ALUser *)alUser withCompletion:(void(^)(ALRegistrationResponse *rResponse, NSError *error))completion;

/// Updates an APNs device token to Applozic server for real-time updates on messages and other events to the device.
///
///
/// APN's device token which is generated from `didRegisterForRemoteNotificationsWithDeviceToken` method of `UIApplicationDelegate` in your AppDelegate file.
/// @param apnDeviceToken An device token which is required for sending APNs push notifications to an iPhone device.
/// @param completion An `ALRegistrationResponse` describing a successful update of token otherwise an error describing the update APNs token failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
///
/// const unsigned *tokenBytes = [deviceToken bytes];
/// NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
///      ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
///      ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
///      ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
///
/// NSString *apnDeviceToken = hexToken;
///
///     if ([[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken]) {
///         return;
///     }
/// [applozicClient updateApnDeviceTokenWithCompletion:apnDeviceToken
///     withCompletion:^(ALRegistrationResponse *rResponse, NSError *error) {
///
///     if (error) {
///        NSLog(@"Failed to update APNs token to applozic server due to: %@",error.localizedDescription);
///        return;
///     }
///
/// }];
/// @endcode
- (void)updateApnDeviceTokenWithCompletion:(NSString *)apnDeviceToken
                            withCompletion:(void(^)(ALRegistrationResponse *rResponse, NSError *error))completion;

/// Sending an attachment message in one-to-one or channel conversation.
///
/// Real-time updates regarding upload status callback are sent to `ApplozicAttachmentDelegate` you need to implement this in your class for callback events.
///
/// @param attachmentMessage An `ALMessage` object for sending an attachment can be build using `ALMessageBuilder`.
/// @note Make sure to set receiver userID for one-to-one or channel for channel and the file name in `imageFilePath` of `ALMessageBuilder` to send the attachment.
///
/// Example: Sending an attachment message in a one-to-one conversation:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; //Pass App ID here
/// applozicClient.attachmentProgressDelegate = self; // Implement `ApplozicAttachmentDelegate` in your class for real time attachment upload status events.
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
/// applozicClient.attachmentProgressDelegate = self; // Implement `ApplozicAttachmentDelegate` in your class for real time attachment upload status events.
///
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
///     alMessageBuilder.groupId = CHANNEL-KEY; // Pass channelKey to channel/group you want to send a attchment message
///     alMessageBuilder.imageFilePath = @"NAME-OF-FILE"; // File name
///     alMessageBuilder.contentType = ALMESSAGE_CONTENT_ATTACHMENT;
/// }];
///
/// [applozicClient sendMessageWithAttachment:alMessage];
///
/// @endcode
- (void)sendMessageWithAttachment:(ALMessage *)attachmentMessage;

/// Sending a text message in one-to-one or channel conversation.
///
///
/// @param alMessage Message object for sending an attachment message can be build using `ALMessageBuilder`.
/// @param completion On Message sent successfully it will have `ALMessage` object with updated message key or an error describing the send message failure.
/// @warning Method `sendTextMessage` is used only for sending text messages not for attachments to send attachment checkout the `-[ApplozicClient sendMessageWithAttachment:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder *alMessageBuilder) {
/// alMessageBuilder.to = @"USER-ID"; // Pass userId to whom you want to send a message otherwise it will be nil.
///                                 OR
/// alMessageBuilder.groupId = @<CHANNEL-KEY>; //Pass channelKey here to whom you want to send a message otherwise it will be nil.
///
/// alMessageBuilder.message = @"MESSAGE-TEXT"; // Pass message text here.
/// }];
///
/// [applozicClient sendTextMessage:alMessage withCompletion:^(ALMessage *message, NSError *error) {
///
///     if (!error) {
///        NSLog(@"Update the UI message is sent to server");
///     }
///
/// }];
///
/// @endcode
- (void)sendTextMessage:(ALMessage *)alMessage withCompletion:(void(^)(ALMessage *message, NSError *error))completion;

/// Gets the list of most recent messages of all conversations.
///
///
/// @param isNextPage Pass NO to load all recent messages otherwise, Pass YES to fetch the next set of 60 older message pageSize you change it by using this settings `[ALUserDefaultsHandler setFetchConversationPageSize:60]`.
/// @param completion An array of `ALMessage` objects otherwise, an error describing the recent message list failure.
///
/// @code
/// @import ApplozicCore;
///
/// BOOL loadNextPage = NO; // Pass YES in case of loading next set of 60 old conversations.
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
/// [applozicClient getLatestMessages:loadNextPage withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
///
///     if (error) {
///         NSLog(@"Error in fetching all recent conversations %@", error.localizedDescription);
///         return;
///     }
///
///     for (ALMessage *message in messageList) {
///         NSLog(@"Message object :%@", [message dictionary]);
///
///         if ([message.groupId intValue]) {
///             // Channel conversation you can get ALChannel by using message.groupId.
///         } else {
///             // One to one conversation you can get the ALContact for receiver message.to.
///         }
///     }
/// }];
/// @endcode
- (void)getLatestMessages:(BOOL)isNextPage withCompletionHandler:(void(^)(NSMutableArray *messageList, NSError *error))completion;

/// Gets a list of messages for the given one-to-one or channel based on the `MessageListRequest` object.
///
///
/// @param messageListRequest Create an `MessageListRequest` for one-to-one or channel conversation.
/// @param completion If messages are fetched successfully it will have a list of `ALMessage` objects for one-to-one or channel conversation otherwise, an error describing the conversation messages failure.
///
///@code
///
///  // Create an message list request with RECEIVER-USER-ID for one to one or CHANNEL-KEY for Channel conversation.
/// MessageListRequest *messagelistRequest = [[MessageListRequest alloc] init];
///
/// messagelistRequest.userId = @"RECEIVER-USER-ID"; // Pass receiver userId to load the messages for one-to-one conversation and  messagelistRequest.channelKey needs to be nil.
///                             OR
/// messagelistRequest.channelKey = CHANNEL-KEY; // Pass channelkey to load the messages for channel conversation and messagelistRequest.userId needs to be nil.
///
/// messagelistRequest.endTimeStamp = createdAtTime; // Pass first message.createdAtTime to load the older messages.
///
/// if ([ALUserDefaultsHandler isServerCallDoneForMSGList:messagelistRequest.userId]) {
///     [ALMessageService getMessageListForContactId:messagelistRequest.userId isGroup:[messagelistRequest.channelKey intValue] channelKey:messagelistRequest.channelKey conversationId:nil startIndex:0 withCompletion:^(NSMutableArray *messageList)  {
///         if (messageList.count) {
///              // Get the messages
///             for (ALMessage *message in messageList) {
///
///                  TODO: Add this meessages to your array and show in your UI.
///                  NSLog(@"Message object :%@", [message dictionary]);
///                  if ([message.groupId intValue]) {
///                     // Channel conversation you can get ALChannel by using message.groupId and message.to that receiver who sent message in conversation.
///                  } else {
///                     // One to one conversation you can get the ALContact for receiver message.to.
///                  }
///             }
///          }
///    }];
/// } else {
///  [self.applozicClient getMessages: messagelistRequest withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
///
///       if (!error) {
///            // Get the messages
///           for (ALMessage *message in messageList) {
///                  TODO: Add this meessages to your array and show in your UI.
///                  NSLog(@"Message object :%@", [message dictionary]);
///                  if ([message.groupId intValue]) {
///                     // Channel conversation you can get ALChannel by using message.groupId and message.to that receiver who sent message in conversation.
///                  } else {
///                     // One to one conversation you can get the ALContact for receiver message.to.
///                  }
///           }
///        }
///  }];
/// }
/// @endcode
- (void)getMessages:(MessageListRequest *)messageListRequest withCompletionHandler:(void(^)(NSMutableArray *messageList, NSError *error))completion;

/// Download an attachment message in the conversation.
///
///
/// @param alMessage An `ALMessage` object for which downloading an attachment in one-to-one or channel conversation.
/// @note Make sure to implement the `ApplozicAttachmentDelegate` in your class for real time download status updates and set the attachmentProgressDelegate for `ApplozicClient` object.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
/// applozicClient.attachmentProgressDelegate = self; // Implement `ApplozicAttachmentDelegate` in your class for real time download status events.
///
/// [applozicClient downloadMessageAttachment:alMessage]; // Pass message object to download.
/// @endcode
- (void)downloadMessageAttachment:(ALMessage *)alMessage;

/// Creating a new channel conversation.
///
///
/// The types of the channel's:
/// PRIVATE = 1,
/// PUBLIC = 2,
/// BROADCAST = 5,
/// OPEN = 6,
/// GROUP_OF_TWO = 7
/// @param channelInfo Create an `ALChannelInfo` object with channel details.
/// @param completion It will be having complete deatils about channel and status, if its error or success otherwise, an error describing the channel create failure.
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
///     if (error) {
///         NSLog(@"Error in creating a channel : %@", error.localizedDescription);
///         return;
///     }
///
///     if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///         NSLog(@"Failed to create channel");
///         return;
///     }
///
///     // Access the channel object.
///     ALChannel *channel = response.alChannel;
///     NSLog(@"Channel has been created successfully object :%@",[channel dictionary]);
///
/// }];
///
/// @endcode
- (void)createChannelWithChannelInfo:(ALChannelInfo *)channelInfo withCompletion:(void(^)(ALChannelCreateResponse *response, NSError *error))completion;

/// Removing a member from the channel conversation.
///
///
/// @param userId UserId of channel member that you wanted to remove from channel conversation.
/// @param channelKey An channel Key from the `ALChannel` object that you want to remove a member from.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the remove member failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient removeMemberFromChannelWithUserId:@"RecieverUserId"
///     andChannelKey:channelKey
///    orClientChannelKey:clientChannelKey
///    withCompletion:^(NSError *error, ALAPIResponse *response) {
///
///     if (error) {
///         NSLog(@"Error in removing a member : %@", error.localizedDescription);
///         return;
///     }
///
///     if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///         NSLog(@"Failed to remove the member from channel");
///         return;
///     }
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
/// @param userId Currently logged-in userId in applozic for leaving from the channel.
/// @param channelKey An Channel key that can be accessed from the `ALChannel` object key.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the leave member failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient leaveMemberFromChannelWithUserId:[ALUserDefaultsHandler getUserId]
///     andChannelKey:channelKey
///    orClientChannelKey:clientChannelKey
///    withCompletion:^(NSError *error, ALAPIResponse *response) {
///
///     if (error) {
///         NSLog(@"Error in leave a member : %@", error.localizedDescription);
///         return;
///     }
///
///     if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///         NSLog(@"Failed to leave a member : %@", response.status);
///         return;
///     }
///
///     NSLog(@"User left successfully from channel.");
///
/// }];
///
/// @endcode
- (void)leaveMemberFromChannelWithUserId:(NSString *)userId
                           andChannelKey:(NSNumber *)channelKey
                      orClientChannelKey:(NSString *)clientChannelKey
                          withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/// Add member to the channel conversation.
///
///
/// @param userId Receiver userId that you want to add in the channel conversation.
/// @param channelKey An Channel key that can be accessed from the `ALChannel` object key.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the add member to channel failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient addMemberToChannelWithUserId:@"RecieverUserId"
///    andChannelKey:channelKey
///   orClientChannelKey:clientChannelKey
///    withCompletion:^(NSError *error, ALAPIResponse *response) {
///
///     if (error) {
///         NSLog(@"Error in add member in channel :%@", error.localizedDescription);
///         return;
///     }
///
///     if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///         NSLog(@"Failed to add member in channel :%@", response.status);
///         return;
///     }
///
///     NSLog(@"User added successfully.");
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
/// @param channelKey An Channel key that can be accessed from the `ALChannel` object key.
/// @param newName Name of the channel.
/// @param imageURL Channel Profile image URL.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param flag YES for updating channel metadata otherwise NO.
/// @param metaData Extra information that can be passed in the channel and can access it later when it's required.
/// @param channelUsers To update channel user's roles like admin, the member the object can be created using the class `ALChannelUser`.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the update channel failure.
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
///     andNewName:@"<CHANNEL-NAME>"
///    andImageURL:@"<IMAGE-URL>"
///    orClientChannelKey:@"<CHANNEL-CLIENT-KEY>"
///    isUpdatingMetaData:NO
///     metadata:metadata
///    orChannelUsers:channelMemberRoleArray
///    withCompletion:^(NSError *error, ALAPIResponse *response) {
///
///     if (error) {
///         NSLog(@"Error in channel update : %@", error.localizedDescription);
///         return;
///     }
///
///     if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///         NSLog(@"Failed to update channel : %@", response.status);
///         return;
///     }
///
///     NSLog(@"Updated channel successfully.");
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

/// Gets the channel information for the given channel Key or client channel key.
///
///
/// @param channelKey An channel Key of the channel.
/// @param clientChannelKey Own Channel client key which you can link with your server otherwise nil.
/// @param completion An error describing the channel information failure otherwise, an `ALChannel` object will have information of channel.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient getChannelInformationWithChannelKey:channelKey
///    orClientChannelKey:channelClientKey
///     withCompletion:^(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse) {
///
///     if (error) {
///         NSLog(@"Error in fetching a channel :%@", error.localizedDescription);
///         return;
///     }
///
///     if (alChannel) {
///         NSLog(@"Channel object is :%@", [alChannel dictionary]);
///     }
///
/// }];
///
///@endcode
- (void)getChannelInformationWithChannelKey:(NSNumber *)channelKey
                         orClientChannelKey:(NSString *)clientChannelKey
                             withCompletion:(void(^)(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse))completion;


/// Logout the user from Applozic.
///
///
/// @param completion An ALAPIResponse will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the logout failure.
/// @note Logout user will clear locally stored data of applozic logged-in user.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient logoutUserWithCompletion:^(NSError *error, ALAPIResponse *response) {
///
/// }];
///
/// @endcode
- (void)logoutUserWithCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

/// Mute/unmute the channel for given channel key and time (in milliseconds).
///
///
/// @param channelKey An Channel key that can be accessed from the `ALChannel` object key.
/// @param notificationTime Mute conversation till milliseconds or unmute channel for the current time in milliseconds.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the mute channel failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient muteChannelOrUnMuteWithChannelKey:channelKey
///      andTime:notificationTime
///     withCompletion:^(ALAPIResponse *response, NSError *error) {
///
///     if (error) {
///         NSLog(@"Failed to mute or unmute the channel got some error : %@",error.localizedDescription);
///         return;
///     }
///
///     if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
///         NSLog(@"Channel muted or unmute successful");
///     }
///
/// }];
///
/// @endcode
- (void)muteChannelOrUnMuteWithChannelKey:(NSNumber *)channelKey
                                  andTime:(NSNumber *)notificationTime
                           withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

/// Unblocks the user from receiving messages and other updates related to the receiver for given receiver userId.
///
///
/// @param userId UserId of the receiver user whom you want to unblock.
/// @param completion It will have YES for the user is unblocked otherwise, an error describing the user unblock failure.
///
/// @code
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient unBlockUserWithUserId:receiverUserId withCompletion:^(NSError *error, BOOL userUnblock) {
///
///     if (error) {
///         NSLog(@"Failed to unblock the user got some error : %@",error.localizedDescription);
///         return;
///     }
///
/// }];
///
/// @endcode
- (void)unBlockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userUnblock))completion;

/// Blocks the user from receiving messages and other updates related to the receiver for given receiver userId.
///
///
/// @param userId UserId of the receiver user whom you want to block.
/// @param completion It will have YES for the user is blocked otherwise, an error describing the user block failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient blockUserWithUserId:receiverUserId withCompletion:^(NSError *error, BOOL userBlock) {
///
///     if (error) {
///         NSLog(@"Failed to block the user got some error : %@",error.localizedDescription);
///         return;
///     }
///
/// }];
///
/// @endcode
- (void)blockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError *error, BOOL userBlock))completion;

/// Mark all the messages of conversation as read in the channel for the given channel key.
///
///
/// @param groupId Channel key to mark all messages of conversation as read.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the conversation read failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"APP-ID"];
///
/// [applozicClient markConversationReadForGroup:CHANNEL-KEY withCompletion:^(NSString *response, NSError *error) {
///
///     if (error) {
///         NSLog(@"Error in conversation read:%@",error);
///         return;
///     }
///
///     NSLog(@"Marked a conversation successfully");
///
/// }];
///
/// @endcode
- (void)markConversationReadForGroup:(NSNumber *)groupId withCompletion:(void(^)(NSString *response, NSError *error))completion;

/// Mark all the messages of conversation as read in the one-to-one conversation for given receiver userId.
///
///
/// @param userId Receiver userId of the user to mark a conversation as read.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the mark conversation failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass App ID here.
///
/// [applozicClient markConversationReadForOnetoOne:@"receiverUserId" withCompletion:^(NSString *response, NSError *error) {
///
///     if (error) {
///         NSLog(@"Error in marking conversation read :%@",error.localizedDescription);
///         return;
///     }
///
///     NSLog(@"Marked a conversation successfully");
///
/// }];
///
/// @endcode
- (void)markConversationReadForOnetoOne:(NSString *)userId withCompletion:(void(^)(NSString *response, NSError *error))completion;

/// APNs push notification messages handling for given application and userInfo.
///
/// Used in `userNotificationCenter` method of UNUserNotificationCenterDelegate and `didReceiveRemoteNotification` method of UIApplicationDelegate.
/// @param application UIApplication of the APNs notification delegate.
/// @param userInfo An userInfo notification dictionary from an `userNotificationCenter` and `didReceiveRemoteNotification`.
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
///
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
///
/// @endcode
- (void)unsubscribeToConversation;

/// Unsubscribe for typing status events of the channel for the given channel key.
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

/// Unsubscribe the typing status events from the one-to-one conversation.
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

/// Sending a typing status in one-to-one or channel conversation.
///
///
/// @param userId For one-to-one conversation pass the receiver userId otherwise nil.
/// @param channelKey For channel conversation pass the channel key from the `ALChannel` object otherwise nil.
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

/// Subscribe to real-time typing events for one-to-one conversation.
///
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here
///
/// [applozicClient subscribeToTypingStatusForOneToOne];
///
/// @endcode
- (void)subscribeToTypingStatusForOneToOne;

/// Subscribe to real-time typing events for channel conversation.
///
///
/// @param channelKey An Unique channel key for subscribing to real-time typing events.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here
///
/// [applozicClient subscribeToTypingStatusForChannel:channelKey]; // Pass the channel key of the channel conversation.
///
/// @endcode
- (void)subscribeToTypingStatusForChannel:(NSNumber *)channelKey;

/// Gets the list of most recent messages of one-one or channel conversations.
///
///
/// @param isNextPage Pass NO to load all the recent messages otherwise. for YES to fetch the next set of 60 older messages to change the older message pageSize you change it by using this settings `[ALUserDefaultsHandler setFetchConversationPageSize:60]`;.
/// @param isGroup YES will give all channel recent conversations, For NO to get the all one-to-one recent conversations.
/// @param completion Array of messages of type `ALMessage` otherwise. an error describing the recent conversations failure.
///
/// @code
/// ApplozicClient *applozicClient = [[ApplozicClient alloc]initWithApplicationKey:@"<APP_ID>"]; // Pass your APP-ID here
///
/// BOOL loadNextPage = NO; // Pass YES in case of loading next set of 60 old conversations.
/// BOOL loadGroups = NO; // Pass YES in case of loading group conversations.
///
/// [applozicClient getLatestMessages:loadNextPage withOnlyGroups:loadGroups withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
///
///     if (error) {
///        NSLog(@"Failed to load the recent conversations :%@",error.localizedDescription);
///        return;
///     }
///
///     for (ALMessage *message in messageList) {
///         NSLog(@"Message object %@",[message dictionary]);
///     }
///
/// }];
/// @endcode
- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler: (void(^)(NSMutableArray *messageList, NSError *error))completion;

@end
