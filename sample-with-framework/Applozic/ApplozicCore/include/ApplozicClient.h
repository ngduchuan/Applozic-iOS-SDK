//
//  ApplozicClient.h
//  Applozic
//
//  Created by Sunil on 12/03/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALChannelService.h"
#import "ALMessageDBService.h"
#import "ALMessageService.h"
#import "ALRegistrationResponse.h"
#import "ALUser.h"
#import "ALUserService.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// error types
typedef NS_ENUM(NSInteger, ApplozicClientError) {
    MessageNotPresent = 1
};

/// Listens to attachment upload and download events.
@protocol ApplozicAttachmentDelegate <NSObject>

/// Called when the attachment download progresses with `bytesReceived` so far.
///
/// `message.fileMeta.size` - `bytesReceived` will give you the bytes remaining.
/// @param message for which the attachment is currently downloading.
- (void)onUpdateBytesDownloaded:(int64_t)bytesReceived withMessage:(ALMessage *)message;

/// Called when the attachment upload progresses with `bytesSent` so far.
///
/// To calculate the bytes remaining find the size of the file in the application directory with the name `message.imageFilePath` and subtract the `bytesSent` from it.
/// @param message for which the attachment is currently uploading.
- (void)onUpdateBytesUploaded:(int64_t)bytesSent withMessage:(ALMessage *)message;

/// Called when attachment upload fails. `message.fileMeta` will be nil.
/// @param message for which the attachment upload failed.
- (void)onUploadFailed:(ALMessage *)message;

/// Called when attachment download fails. `message.imageFilePath` will be nil.
/// @param message for which the attachment download failed.
- (void)onDownloadFailed:(ALMessage *)message;

/// Called when the attachment successfully uploads.
///
/// @param updatedMessage When a message is uploaded, Applozic generates a new Message object with updated key and file meta.
/// @param oldMessageKey The old message key. You can use this to find the old message object in your application model, and replace it with the new one.
- (void)onUploadCompleted:(ALMessage *)updatedMessage withOldMessageKey:(NSString *)oldMessageKey;

/// Called when the attachment successfully downloads. Access it via ALMessage.imageFilePath.
- (void)onDownloadCompleted:(ALMessage *)updatedMessage;

@end

/// Provides public methods for:
///
/// - Initialization of the SDK.
/// - User Authentication.
/// - Listing, sending and receiving messages both 1:1 and group messages.
/// - Real-time Events.
///
///  @note To access any method get the `ApplozicClient` object using `-[ApplozicClient initWithApplicationKey:]` or `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
@interface ApplozicClient : NSObject <NSURLConnectionDataDelegate>

/// For real time updates of attachment upload or download status.
@property (nonatomic, weak) id<ApplozicAttachmentDelegate> _Nullable attachmentProgressDelegate;

/// Used to make API calls related to conversations.
@property (nonatomic, retain) ALMessageService *messageService;

/// Used to store data related to `ALMessage`.
@property (nonatomic, retain) ALMessageDBService *messageDbService;

/// Used to make API calls related to `ALUser`.
@property (nonatomic, retain) ALUserService *userService;

/// Used to makie API calls related to `ALChannel`.
@property (nonatomic, retain) ALChannelService *channelService;

/// Gives callbacks for real-time update events for Messages, channels, Users, and Typing.
/// @warning Do not assign this property. It won't work properly if you do. Instead, use the `-[ApplozicClient initWithApplicationKey:withDelegate:]` initializer, which assigns this property.
@property (nonatomic, weak) id<ApplozicUpdatesDelegate> _Nullable delegate;

/// init is not avaliable for accessing.
- (instancetype)init NS_UNAVAILABLE;

/// Returns an `ApplozicClient` object for given App-ID.
///
/// @param appId The unique identifier of APP-ID which you have got from the [console](https://console.applozic.com/login)
///
/// Example: Get `ApplozicClient` using below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
/// @endcode
- (instancetype)initWithApplicationKey:(NSString *)appId;

/// Returns an `ApplozicClient` object for given App-ID and sets the `ApplozicUpdatesDelegate` for real-time updates events.
///
/// @param appId The unique identifier of APP-ID which you have got from the [console](https://console.applozic.com/login).
/// @param delegate For real-time update events for Messages, Channel, User, and Typing.
///
/// Example: Get `ApplozicClient` using below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID" withDelegate:self]; // Pass your APP-ID here and set the delegate.
/// @endcode
- (instancetype)initWithApplicationKey:(NSString *)appId withDelegate:(id<ApplozicUpdatesDelegate>)delegate;

/// Logs in or registers your `ALUser`. This must be done before using any of our API SDK methods.
///
/// If the userId is not present in the servers, a new one will be created and registered. Otherwise, the existing user will be authenticated and logged in.
///
/// @param user An `ALUser` object details for identifying the user on the server, userId, and authenticationTypeId are mandatory fields.
/// @param completion An `ALRegistrationResponse` describing a successful login or an error describing the authentication failure.
///
/// Example: To log in a user to Applozic server use the below code:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// ALUser *user = [[ALUser alloc] init];
/// user.userId = @"58935395796"; // User-id is the primary identification for a user and is unique and NOTE : +,*,? are not allowed chars in userId.
/// user.password = @"cat345"; // User password.
/// user.displayName = @"Sunil"; // User's Display Name.
/// user.imageLink = @"http://mywebsite.com/user_profile_picture.jpg"; // Pass Profile image URL link.
/// user.authenticationTypeId = APPLOZIC; // Set Authentication type as APPLOZIC by default.
/// [ALUserDefaultsHandler setUserAuthenticationTypeId:user.authenticationTypeId];
///
/// [applozicClient loginUser:user withCompletion:^(ALRegistrationResponse * _Nullable response, NSError * _Nullable error) {
///
///   if (!error) {
///      NSLog(@"User Login success");
///   }
///
/// }];
///
/// @endcode
- (void)loginUser:(ALUser *)user withCompletion:(void(^)(ALRegistrationResponse * _Nullable response, NSError * _Nullable error))completion;

/// Enables push notification for real-time updates on messages and other events to the device.
///
/// You can get the APN's device token from `didRegisterForRemoteNotificationsWithDeviceToken` method of `UIApplicationDelegate` in your AppDelegate file.
/// @note Make sure the push notification is enabled from `Signing and Capabilities` in Xcode to get the device token and use a real iOS device.
/// @param apnDeviceToken An device token which is required for sending APNs push notifications to an iPhone device.
/// @param completion An `ALRegistrationResponse` describing a successful update of token otherwise an error describing the update APNs token failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// const unsigned *tokenBytes = [deviceToken bytes];
/// NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
///  ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
///  ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
///  ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
///
/// NSString *apnDeviceToken = hexToken;
///
/// if ([[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken]) {
///     NSLog(@"APN's device token is same returning from updating to server");
///     return;
/// }
///
/// [applozicClient updateApnDeviceTokenWithCompletion:apnDeviceToken
///  withCompletion:^(ALRegistrationResponse * _Nullable response, NSError * _Nullable error) {
///
///   if (error) {
///       NSLog(@"Failed to update APNs token to Applozic server due to: %@",error.localizedDescription);
///       return;
///   }
///
/// }];
/// @endcode
- (void)updateApnDeviceTokenWithCompletion:(NSString *)apnDeviceToken
                            withCompletion:(void(^)(ALRegistrationResponse * _Nullable response, NSError * _Nullable error))completion;

/// Sends an attachment message in one-to-one or channel conversation.
///
/// Real-time updates regarding upload status are sent to the `ApplozicAttachmentDelegate`. You need to implement this in your class for callbacks.
///
/// 1. Updated bytes so far you can see : `-[ApplozicAttachmentDelegate onUpdateBytesUploaded:withMessage:]`.
/// 2. If upload fails callback will be called : `-[ApplozicAttachmentDelegate onUploadFailed:]`.
/// 3. Successful sending an attachment callback will be called : `-[ApplozicAttachmentDelegate onUploadCompleted:withOldMessageKey:]`.
///
/// @param message Create an `ALMessage` object using `ALMessageBuilder` set receiver userId for one-to-one or channel key from `ALChannel` and file name in `imageFilePath`.
/// @note Make sure the file is saved and exists in the Application document directory using the file name will pick the file from there and upload it to servers.
///
/// Example: Sending an attachment message in a one-to-one conversation:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
/// applozicClient.attachmentProgressDelegate = self; // Implement `ApplozicAttachmentDelegate`in your class for real time attachment upload status events.
///
/// ALMessage *message = [ALMessage build:^(ALMessageBuilder *messageBuilder) {
///     messageBuilder.to = @"589353957989"; // Pass Receiver userId to whom you want to send a message.
///     messageBuilder.imageFilePath = @"home-image.jpg"; // Attachment File name.
///     messageBuilder.contentType = ALMESSAGE_CONTENT_ATTACHMENT; // Attachment content type.
/// }];
///
/// [applozicClient sendMessageWithAttachment:message];
///
/// @endcode
///
/// Example: Sending an attachment message in channel conversation:
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
/// applozicClient.attachmentProgressDelegate = self; // Implement `ApplozicAttachmentDelegate` in your class for real time attachment upload status events.
///
/// ALMessage *message = [ALMessage build:^(ALMessageBuilder * messageBuilder) {
///     messageBuilder.groupId = @12327283; // Pass channelKey from ALChannel object you want to send a attchment message.
///     messageBuilder.imageFilePath = @"home-image.jpg"; // Attachment File name.
///     messageBuilder.contentType = ALMESSAGE_CONTENT_ATTACHMENT; // Attachment content type.
/// }];
///
/// [applozicClient sendMessageWithAttachment:message];
///
/// @endcode
- (void)sendMessageWithAttachment:(ALMessage *)message;

/// Sends a text message in one-to-one or channel conversation.
///
/// @param message Create an `ALMessage` object using `ALMessageBuilder` with message text which is non-nil for one-to-one or channel conversation.
/// @param completion On message sent successfully it will have `ALMessage` object with an updated message key or an error describing the send message failure.
/// @warning Method `sendTextMessage` is used only for sending text messages not for attachments. To send attachment checkout `-[ApplozicClient sendMessageWithAttachment:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// ALMessage *message = [ALMessage build:^(ALMessageBuilder *messageBuilder) {
///     messageBuilder.message = @"Hi How are you?"; // Pass message text here.
///
///     messageBuilder.to = @"1232722828288283"; // Pass userId to whom you want to send a message otherwise it will be nil.
///         OR
///     messageBuilder.groupId = @12327283; // Pass channelKey here to whom you want to send a message otherwise it will be nil.
///
/// }];
///
/// [applozicClient sendTextMessage:message withCompletion:^(ALMessage * _Nullable message, NSError * _Nullable error) {
///
///   if (!error) {
///       NSLog(@"Update the UI message is sent to server");
///   }
///
/// }];
///
/// @endcode
- (void)sendTextMessage:(ALMessage *)message withCompletion:(void(^)(ALMessage * _Nullable message, NSError * _Nullable error))completion;

/// Gets list of the most recent messages for each conversation.
///
/// @param isNextPage Pass NO to get all recent messages otherwise, Pass YES to get the next set of 60 older messages and the message fetch limit can be changed by using settings `[ALUserDefaultsHandler setFetchConversationPageSize:60]`.
/// @param completion An array of `ALMessage` objects otherwise, an error describing the recent message list failure.
///
/// @code
/// @import ApplozicCore;
///
/// BOOL loadNextPage = NO; // Pass YES in case of loading next set of 60 old recent messages.
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient getLatestMessages:loadNextPage withCompletionHandler:^(NSMutableArray * _Nullable messages, NSError * _Nullable error) {
///
///   if (error) {
///       NSLog(@"Error in fetching all recent conversations %@", error.localizedDescription);
///       return;
///   }
///
///   for (ALMessage *message in messages) {
///
///     NSLog(@"Message object :%@", [message dictionary]);
///
///     if ([message.groupId intValue]) {
///        // Channel conversation you can get ALChannel by using message.groupId.
///     } else {
///        // One to one conversation you can get the ALContact for receiver message.to.
///     }
///   }
/// }];
/// @endcode
- (void)getLatestMessages:(BOOL)isNextPage withCompletionHandler:(void(^)(NSMutableArray * _Nullable messages, NSError * _Nullable error))completion;

/// Gets the list of messages for the given one-to-one or channel conversation.
///
/// @param messageListRequest Create an `MessageListRequest` with receiver userId for one-to-one or channelKey for channel conversation and to load older messages set first message createdAtTime in endTimeStamp of `MessageListRequest`.
/// @param completion If messages are fetched successfully it will have an array of `ALMessage` objects for one-to-one or channel conversation otherwise, an error describing the conversation messages failure.
///
///@code
///@import ApplozicCore;
///
/// // Create a message list request with RECEIVER-USER-ID for one-to-one or CHANNEL-KEY for Channel conversation.
/// MessageListRequest *messagelistRequest = [[MessageListRequest alloc] init];
///
/// messagelistRequest.userId = @"RECEIVER-USER-ID"; // Pass receiver userId to load the messages for one-to-one conversation and messagelistRequest.channelKey set to be nil.
///        OR
/// messagelistRequest.channelKey = CHANNEL-KEY; // Pass channelkey to load the messages for channel conversation and messagelistRequest.userId set to be nil.
///
/// messagelistRequest.endTimeStamp = createdAtTime; // Use this to load older messages, Pass first message.createdAtTime to load the older messages.
///
/// NSString *chatId = messagelistRequest.userId != nil ? messagelistRequest.userId : [messagelistRequest.channelKey stringValue];
///
/// if ([ALUserDefaultsHandler isServerCallDoneForMSGList:chatId]) {
///
///   [ALMessageService getMessageListForContactId:messagelistRequest.userId isGroup:[messagelistRequest.channelKey intValue] channelKey:messagelistRequest.channelKey conversationId:nil startIndex:0 withCompletion:^(NSMutableArray *messages) {
///
///     if (messages.count) {
///        for (ALMessage *message in messages) {
///
///             TODO: Add this meessages to your array and show in your UI.
///             NSLog(@"Message object :%@", [message dictionary]);
///
///            if ([message.groupId intValue]) {
///              // Channel conversation you can get ALChannel by using message.groupId and message.to that receiver who sent message in conversation.
///            } else {
///              // One to one conversation you can get the ALContact for receiver message.to.
///            }
///        }
///     }
///   }];
/// } else {
///   [self.applozicClient getMessages: messagelistRequest withCompletionHandler:^(NSMutableArray * _Nullable messages, NSError * _Nullable error) {
///
///     if (!error) {
///        // Get the messages
///        for (ALMessage *message in messages) {
///
///            TODO: Add this meessages to your array and show in your UI.
///            NSLog(@"Message object :%@", [message dictionary]);
///
///           if ([message.groupId intValue]) {
///              // Channel conversation you can get ALChannel by using message.groupId and message.to that receiver who sent message in conversation.
///            } else {
///              // One to one conversation you can get the ALContact for receiver message.to.
///            }
///         }
///     }
///   }];
/// }
/// @endcode
- (void)getMessages:(MessageListRequest *)messageListRequest withCompletionHandler:(void(^)(NSMutableArray * _Nullable messages, NSError * _Nullable error))completion;

/// Downloads the attachment file for the message.
///
/// An real-time updates regarding download status are sent to `ApplozicAttachmentDelegate` you need to implement in your class for callbacks.
///
/// 1. Downloaded bytes so far you can see : `-[ApplozicAttachmentDelegate onUpdateBytesDownloaded:withMessage:]`.
/// 2. If download fails callback will be called : `-[ApplozicAttachmentDelegate onDownloadFailed:]`.
/// 3. Successful downloaded an attachment callback will be called : `-[ApplozicAttachmentDelegate onDownloadCompleted:]`.
///
/// @param message An `ALMessage` object for which downloading an attachment in one-to-one or channel conversation.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
/// applozicClient.attachmentProgressDelegate = self; // Implement `ApplozicAttachmentDelegate`in your class for real-time download status events.
///
/// [applozicClient downloadMessageAttachment:message]; // Pass `ALMessage` object to download and make sure message filemeta object is not nil.
/// @endcode
- (void)downloadMessageAttachment:(ALMessage *)message;

/// Downloads the Thumbnail Image of an attachment.
///
/// @param message An `ALMessage` object for which downloading an thumbnail image in one-to-one or channel conversation
- (void)downloadThumbnailImage:(ALMessage *)message;

/// Creates a new channel conversation for the given `ALChannelInfo` object.
///
/// The types of the channel's are:
/// PRIVATE = 1, // Only admin can add member in the channel.
/// PUBLIC = 2, // Any one can join in the channel.
/// BROADCAST = 5, // One way broadcast messages in channel.
/// GROUP_OF_TWO = 7 // Group of two same as one-to-one chat.
/// @param channelInfo Create an `ALChannelInfo` object with channel details. The groupName, groupMemberList and type from `ALChannelInfo` object are mandatory fields.
/// @param completion It will be having complete details about channel and status, if its error or success in create channel otherwise, an error describing the channel create failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// // Channel members.
/// NSMutableArray *channelMemberArray = [[NSMutableArray alloc] init];
///
/// [channelMemberArray addObject:@"MemberUserId1"];
/// [channelMemberArray addObject:@"MemberUserId2"];
///
/// // Channel info.
/// ALChannelInfo *channelInfo = [[ALChannelInfo alloc] init];
/// channelInfo.groupName = @"Home Channel"; // Channel name.
/// channelInfo.imageUrl = @"http://mywebsite.com/channel_profile_picture.jpg"; // Channel Image URL.
/// channelInfo.groupMemberList = channelMemberArray; // Channel members userId array.
/// channelInfo.type = PUBLIC; // Channel type.
///
/// [applozicClient createChannelWithChannelInfo:channelInfo withCompletion:^(ALChannelCreateResponse * _Nullable response, NSError * _Nullable error) {
///
///   if (error) {
///       NSLog(@"Error in creating a channel : %@", error.localizedDescription);
///       return;
///   }
///
///   if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///       NSLog(@"Failed to create channel");
///       return;
///   }
///
///       // Access the channel object.
///       ALChannel *channel = response.alChannel;
///       NSLog(@"Channel has been created successfully object :%@",[channel dictionary]);
///
/// }];
///
/// @endcode
- (void)createChannelWithChannelInfo:(ALChannelInfo *)channelInfo
                      withCompletion:(void(^)(ALChannelCreateResponse * _Nullable response,  NSError * _Nullable error))completion;

/// Removes a member from the channel conversation.
///
/// @param userId Receiver userId of channel member you want to remove from channel conversation.
/// @param channelKey An channel key from the `ALChannel` object that you want to remove a member from otherwise, pass nil if you have your client channel key.
/// @param clientChannelKey Own client channel key which you have linked channels with your server otherwise, pass nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the remove member failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient removeMemberFromChannelWithUserId:@"12328833838"
///  andChannelKey:@74648473
/// orClientChannelKey:nil
/// withCompletion:^(NSError * _Nullable error, ALAPIResponse * _Nullable response) {
///
///   if (error) {
///       NSLog(@"Error in removing a member : %@", error.localizedDescription);
///       return;
///   }
///
///   if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///       NSLog(@"Failed to remove the member from channel");
///       return;
///   }
///
///   NSLog(@"Successfully Member has been removed from channel");
///
/// }];
/// @endcode
- (void)removeMemberFromChannelWithUserId:(NSString *)userId
                            andChannelKey:(NSNumber * _Nullable)channelKey
                       orClientChannelKey:(NSString * _Nullable)clientChannelKey
                           withCompletion:(void(^)(NSError * _Nullable error, ALAPIResponse * _Nullable response))completion;

/// Used for leaving a member from the channel conversation.
///
/// @param userId Currently logged-in userId in applozic for leaving from the channel.
/// @param channelKey An Channel key that can be accessed from the `ALChannel` object key otherwise, pass nil if you have your client channel key.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the leave member failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient leaveMemberFromChannelWithUserId:[ALUserDefaultsHandler getUserId]
///  andChannelKey:@3738278
/// orClientChannelKey:nil
/// withCompletion:^(NSError * _Nullable error, ALAPIResponse * _Nullable response) {
///
///   if (error) {
///       NSLog(@"Error in leave a member : %@", error.localizedDescription);
///       return;
///   }
///
///   if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///       NSLog(@"Failed to leave a member : %@", response.status);
///       return;
///   }
///
///   NSLog(@"User left successfully from channel.");
///
/// }];
///
/// @endcode
- (void)leaveMemberFromChannelWithUserId:(NSString * _Nullable)userId
                           andChannelKey:(NSNumber * _Nullable)channelKey
                      orClientChannelKey:(NSString * _Nullable)clientChannelKey
                          withCompletion:(void(^)(NSError * _Nullable error, ALAPIResponse * _Nullable response))completion;

/// Adds a member to the channel conversation.
///
/// @param userId Receiver userId that you want to add in the channel conversation.
/// @param channelKey An Channel key that can be accessed from the `ALChannel` object key otherwise, pass nil if you have your client channel key.
/// @param clientChannelKey Own Channel client key which you have linked with your server otherwise nil.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the add member to channel failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient addMemberToChannelWithUserId:@"574839292943"
/// andChannelKey:@48493839
/// orClientChannelKey:nil
/// withCompletion:^(NSError * _Nullable error, ALAPIResponse * _Nullable response) {
///
///  if (error) {
///      NSLog(@"Error in add member in channel :%@", error.localizedDescription);
///      return;
///  }
///
///  if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///      NSLog(@"Failed to add member in channel :%@", response.status);
///      return;
///  }
///
///  NSLog(@"User added successfully.");
///
/// }];
/// @endcode
- (void)addMemberToChannelWithUserId:(NSString * _Nullable)userId
                       andChannelKey:(NSNumber * _Nullable)channelKey
                  orClientChannelKey:(NSString * _Nullable)clientChannelKey
                      withCompletion:(void(^)(NSError * _Nullable error, ALAPIResponse *_Nullable response))completion;

/// Used for updating channel information.
///
/// @param channelKey An channel key that can be accessed from the `ALChannel` object key.
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
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// // Channel member roles.
/// ALChannelUser *channelUser = [[ALChannelUser alloc] init];
/// channelUser.userId = @"MemberUserId1";
/// channelUser.role = [NSNumber numberWithInt:ADMIN];
///
/// // Channel metadata.
/// NSMutableArray *channelMemberRoleArray = [[NSMutableArray alloc] init];
/// [channelMemberRoleArray addObject:channelUser];
///
/// [applozicClient updateChannelWithChannelKey:@48493839
///  andNewName:@"My Home channel"
/// andImageURL:@"http://mywebsite.com/home_channel_profile_picture.jpg"
/// orClientChannelKey:nil
/// isUpdatingMetaData:NO
///  metadata:nil
/// orChannelUsers:channelMemberRoleArray
/// withCompletion:^(NSError * _Nullable error, ALAPIResponse * _Nullable response) {
///
///     if (error) {
///          NSLog(@"Error in channel update : %@", error.localizedDescription);
///          return;
///     }
///
///     if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
///          NSLog(@"Failed to update channel : %@", response.status);
///          return;
///     }
///
///     NSLog(@"Updated channel successfully.");
///
/// }];
/// @endcode
- (void)updateChannelWithChannelKey:(NSNumber * _Nullable)channelKey
                         andNewName:(NSString * _Nullable)newName
                        andImageURL:(NSString * _Nullable)imageURL
                 orClientChannelKey:(NSString * _Nullable)clientChannelKey
                 isUpdatingMetaData:(BOOL)flag
                           metadata:(NSMutableDictionary * _Nullable)metaData
                     orChannelUsers:(NSMutableArray * _Nullable)channelUsers
                     withCompletion:(void(^)(NSError * _Nullable error, ALAPIResponse * _Nullable response))completion;

/// Gets the channel information for the given channel Key or client channel key.
///
/// @param channelKey Identifier for the `ALChannel`.
/// @param clientChannelKey Own channel client key which you can link with your server otherwise nil.
/// @param completion An error describing the channel information failure otherwise, an `ALChannel` object will have information of channel.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient getChannelInformationWithChannelKey:@474837
/// orClientChannelKey:nil
///  withCompletion:^(NSError * _Nullable error, ALChannel * _Nullable channel, ALChannelFeedResponse * _Nullable channelResponse) {
///
///     if (error) {
///         NSLog(@"Error in fetching a channel :%@", error.localizedDescription);
///         return;
///     }
///
///     if (channel) {
///         NSLog(@"Channel object is :%@", [channel dictionary]);
///     }
///
/// }];
///
///@endcode
- (void)getChannelInformationWithChannelKey:(NSNumber * _Nullable)channelKey
                         orClientChannelKey:(NSString * _Nullable)clientChannelKey
                             withCompletion:(void(^)(NSError * _Nullable error,
                                                     ALChannel * _Nullable channel,
                                                     ALChannelFeedResponse * _Nullable channelResponse))completion;

/// Logout the user from Applozic.
///
/// @param completion An ALAPIResponse will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the logout failure.
/// @note Logout user will clear locally stored data of Applozic logged-in user.
/// @warning Mostly logout method `-[ApplozicClient logoutUserWithCompletion:]` needs to be called on your App logout success.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient logoutUserWithCompletion:^(NSError * _Nullable error, ALAPIResponse * _Nullable response) {
///
///     NSLog(@"Applozic logout completed");
/// }];
///
/// @endcode
- (void)logoutUserWithCompletion:(void(^)(NSError * _Nullable error, ALAPIResponse * _Nullable response))completion;

/// Mute or unmute the channel for a given channel key and time (in milliseconds).
///
/// @param channelKey An Channel key that can be accessed from the `ALChannel` object key.
/// @param notificationTime The time (in milliseconds) for which to mute or unmute channel.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the mute channel failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient muteChannelOrUnMuteWithChannelKey:@474837
///  andTime:notificationTime
///  withCompletion:^(ALAPIResponse * _Nullable response, NSError * _Nullable error) {
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
                           withCompletion:(void(^)(ALAPIResponse * _Nullable response, NSError * _Nullable error))completion;

/// Unblocks the user from receiving messages and other updates related to the receiver for given receiver userId.
///
/// @param userId UserId of the receiver user whom you want to unblock.
/// @param completion It will have YES for the user is unblocked otherwise, an error describing the user unblock failure.
///
/// @code
/// @import ApplozicCore;
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient unBlockUserWithUserId:@"38484848" withCompletion:^(NSError * _Nullable error, BOOL userUnblock) {
///
///  if (error) {
///      NSLog(@"Failed to unblock the user got some error : %@",error.localizedDescription);
///      return;
///  }
///
/// }];
///
/// @endcode
- (void)unBlockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError * _Nullable error, BOOL userUnblock))completion;

/// Blocks the user from receiving messages and other updates related to the receiver for given receiver userId.
///
/// @param userId UserId of the receiver user whom you want to block.
/// @param completion It will have YES for the user is blocked otherwise, an error describing the user block failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient blockUserWithUserId:@"38484848" withCompletion:^(NSError * _Nullable error, BOOL userBlock) {
///
///     if (error) {
///         NSLog(@"Failed to block the user got some error : %@",error.localizedDescription);
///         return;
///     }
///
/// }];
///
/// @endcode
- (void)blockUserWithUserId:(NSString *)userId withCompletion:(void(^)(NSError * _Nullable error, BOOL userBlock))completion;

/// Mark all the messages of conversation as read in the channel for the given channel key.
///
/// @param groupId Channel key to mark all messages of conversation as read.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the conversation read failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient markConversationReadForGroup:@474837 withCompletion:^(NSString * _Nullable response, NSError * _Nullable error) {
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
- (void)markConversationReadForGroup:(NSNumber *)groupId withCompletion:(void(^)(NSString * _Nullable response, NSError * _Nullable error))completion;

/// Mark all the messages of conversation as read in the one-to-one conversation for given receiver userId.
///
/// @param userId Receiver userId of the user to mark a conversation as read.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the mark conversation failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID"]; // Pass your APP-ID here.
///
/// [applozicClient markConversationReadForOnetoOne:@"38484848" withCompletion:^(NSString * _Nullable response, NSError * _Nullable error) {
///
///     if (error) {
///         NSLog(@"Error in marking conversation read :%@",error.localizedDescription);
///         return;
///      }
///
///     NSLog(@"Marked a conversation successfully");
///
/// }];
///
/// @endcode
///
- (void)markConversationReadForOnetoOne:(NSString *)userId withCompletion:(void(^)(NSString * _Nullable response, NSError * _Nullable error))completion;

/// APNs push notification messages handling for given application and userInfo.
///
/// Used in `userNotificationCenter` method of UNUserNotificationCenterDelegate and `didReceiveRemoteNotification` method of UIApplicationDelegate.
/// @param application UIApplication of the APNs notification delegate.
/// @param userInfo An userInfo notification dictionary from an `userNotificationCenter` and `didReceiveRemoteNotification`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"APP-ID" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// [applozicClient notificationArrivedToApplication:application withDictionary:userInfo];
///
/// @endcode
- (void)notificationArrivedToApplication:(UIApplication *)application withDictionary:(NSDictionary *)userInfo;

/// Subscribe for all real-time update events for conversations.
///
/// Use `ApplozicUpdatesDelegate` to receive the events.
///
/// @note Before calling this method make sure the `ApplozicUpdatesDelegate` was set, using `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// [applozicClient subscribeToConversation];
///
/// @endcode
- (void)subscribeToConversation;

/// Unsubscribe for all real-time update events for conversations.
///
/// @note Before calling this method make sure the `ApplozicUpdatesDelegate` was set, using `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// [applozicClient unsubscribeToConversation];
///
/// @endcode
- (void)unsubscribeToConversation;

/// Unsubscribe to typing status events for the channel.
///
/// @note Before calling this method make sure the `ApplozicUpdatesDelegate` was set, using `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
/// @param channelKey Use `ALChannel` to get the channel key.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// [applozicClient subscribeToTypingStatusForChannel:@474837]; // Pass the Channel key of the `ALChannel`
///
/// @endcode
- (void)unSubscribeToTypingStatusForChannel:(NSNumber *)channelKey;

/// Unsubscribe to typing status events for the one-to-one conversation.
///
/// @note Before calling this method make sure the `ApplozicUpdatesDelegate` was set, using `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// [applozicClient unSubscribeToTypingStatusForOneToOne];
///
/// @endcode
- (void)unSubscribeToTypingStatusForOneToOne;

/// Sending a typing status in one-to-one or channel conversation.
///
/// @param userId For one-to-one conversation pass the receiver's userId, otherwise nil.
/// @param channelKey For a group conversation pass the channel key from the `ALChannel` object, otherwise nil.
/// @param isTyping YES to start the typing and NO to stop the typing in conversation.
/// @note Before calling this method make sure the `ApplozicUpdatesDelegate` was set, using `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// // Sending typing status in one-to-one.
/// [applozicClient sendTypingStatusForUserId:@"38484848" orForGroupId:nil withTyping:typingStarted];
///
/// // Sending typing status in Channel.
/// [applozicClient sendTypingStatusForUserId:nil orForGroupId:@474837 withTyping:typingStarted];
/// @endcode
- (void)sendTypingStatusForUserId:(NSString * _Nullable)userId orForGroupId:(NSNumber * _Nullable)channelKey withTyping:(BOOL)isTyping;

/// Subscribe to real-time typing events for one-to-one conversation.
///
/// To receive typing events, use `-[ApplozicUpdatesDelegate onUpdateTypingStatus:status:]`.
///
/// @note Before calling this method make sure the `ApplozicUpdatesDelegate` was set, using `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// [applozicClient subscribeToTypingStatusForOneToOne];
///
/// @endcode
- (void)subscribeToTypingStatusForOneToOne;

/// Subscribe to real-time typing events for channel conversation.
///
/// To receive the typing events, use `-[ApplozicUpdatesDelegate onUpdateTypingStatus:status:]`.
///
/// @param channelKey to identify the channel to subscribe to.
/// @note Before calling this method make sure the `ApplozicUpdatesDelegate` was set, using `-[ApplozicClient initWithApplicationKey:withDelegate:]`.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>" withDelegate:self]; // Pass your APP-ID here and `ApplozicUpdatesDelegate` implement in your class.
///
/// [applozicClient subscribeToTypingStatusForChannel:@474837]; // Pass the channel key of the channel conversation.
///
/// @endcode
- (void)subscribeToTypingStatusForChannel:(NSNumber *)channelKey;

/// Gets the array of most recent messages of one-one or channel conversations.
///
/// @param isNextPage Pass NO to load all the recent messages. YES to fetch the next set of 60 older messages. This number can be changed using `[ALUserDefaultsHandler setFetchConversationPageSize:60]`;.
/// @param isGroup YES will give all channel recent conversations, For NO to get the all one-to-one recent conversations.
/// @param completion An array of messages of type `ALMessage` otherwise. an error describing the recent conversations failure.
///
/// @code
/// @import ApplozicCore;
///
/// ApplozicClient *applozicClient = [[ApplozicClient alloc] initWithApplicationKey:@"<APP_ID>"]; // Pass your APP-ID here
///
/// BOOL loadNextPage = NO; // Pass YES in case of loading next set of 60 old conversations.
/// BOOL loadGroups = NO; // Pass YES in case of loading group conversations.
///
/// [applozicClient getLatestMessages:loadNextPage withOnlyGroups:loadGroups withCompletionHandler:^(NSMutableArray * _Nullable messages, NSError * _Nullable error) {
///
///     if (error) {
///         NSLog(@"Failed to load the recent conversations :%@",error.localizedDescription);
///         return;
///     }
///
///     for (ALMessage *message in messages) {
///          NSLog(@"Message object %@",[message dictionary]);
///     }
///
/// }];
/// @endcode
- (void)getLatestMessages:(BOOL)isNextPage
           withOnlyGroups:(BOOL)isGroup
    withCompletionHandler: (void(^)(NSMutableArray *_Nullable messages, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
