//
//  ALMessage.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALApplozicSettings.h"
#import "ALConstant.h"
#import "ALFileMetaInfo.h"
#import "ALJson.h"
#import "ALMessageBuilder.h"
#import <CoreData/NSManagedObject.h>
#import <Foundation/Foundation.h>

/// Default message content type for text messages.
static int const ALMESSAGE_CONTENT_DEFAULT = 0;

/// Message content type is used for attachment messages.
static int const ALMESSAGE_CONTENT_ATTACHMENT = 1;

/// Message content type is used for location messages.
static int const ALMESSAGE_CONTENT_LOCATION = 2;

/// This message content type is used for Rich and HTML messages.
static int const ALMESSAGE_CONTENT_TEXT_HTML = 3;

/// :nodoc:
static int const ALMESSAGE_CONTENT_PRICE = 4;

/// :nodoc:
static int const ALMESSAGE_CONTENT_TEXT_URL = 5;

/// Message content type is used for contact attachment.
static int const ALMESSAGE_CONTENT_VCARD = 7;

/// Message content type is used for audio attachment.
static int const ALMESSAGE_CONTENT_AUDIO = 8;

/// Message content type is used for video attachment.
static int const ALMESSAGE_CONTENT_CAMERA_RECORDING = 9;

/// Message content type is used for channel action.
static int const ALMESSAGE_CHANNEL_NOTIFICATION = 10;

/// :nodoc:
static int const ALMESSAGE_CONTENT_CUSTOM = 101;

/// :nodoc:
static int const ALMESSAGE_CONTENT_HIDDEN = 11;

/// :nodoc:
static NSString *const AL_CATEGORY_PUSHNNOTIFICATION = @"PUSHNOTIFICATION";

/// :nodoc:
static NSString *const AL_CATEGORY_HIDDEN = @"HIDDEN";

/// Reply message key where the message key of the parent message set in the value.
static NSString *const AL_MESSAGE_REPLY_KEY = @"AL_REPLY";

/// Sent message type. The message is sent by logged-in user.
static NSString *const AL_OUT_BOX = @"5";

/// Received message type.
static NSString *const AL_IN_BOX = @"4";

/// :nodoc:
static NSString *const AL_RESET_UNREAD_COUNT = @"AL_RESET_UNREAD_COUNT";

/// For internal use only.
static NSString *const APPLOZIC_CATEGORY_KEY = @"category";

/// `ALReplyType` is used for knowing the message is replied to or hidden reply type after the message is deleted.
typedef enum {
    /// Non reply message.
    AL_NOT_A_REPLY,
    /// An replied message of parent message.
    AL_A_REPLY,
    /// If parent message is deleted that message is marked as hidden.
    AL_REPLY_BUT_HIDDEN,
}ALReplyType;

/**
 * Model class for an Applozic Message.
 *
 * A message as the name suggests, data is sent and received between two users.
 * A message has a message string, a sender-id (to) or a group-id (groupId), a key to identify it
 * as well as other data like attachment information, status information, etc.
 * The message metadata dictionary field can be used to send custom key-value information with the message.
 */
@interface ALMessage : ALJson

/// Message key is a unique identifying key for the `ALMessage` object.
///
/// This message key is used in all the places related to Message for performing the operation on Core Data.
@property (nonatomic, copy) NSString *key;

/// Device key is used on the server to identify from which device the message is sent in the conversation.
@property (nonatomic, copy) NSString *deviceKey;

/// User primary key is used on the server to identify from which user the message is sent in the conversation.
@property (nonatomic, copy) NSString *userKey;

/// UserId of receiver user currently sent a message in one-to-one or channel conversation.
@property (nonatomic, copy) NSString *to;

/// Text message.
@property (nonatomic, copy) NSString *message;

/// :nodoc:
@property (nonatomic, assign) BOOL sendToDevice;

/// :nodoc:
@property (nonatomic, assign) BOOL shared;

/// Created at the time which is in milliseconds.
/// This will be useful for showing the time of the message sent or received in chat and also to load the older message based on the created time.
@property (nonatomic, copy) NSNumber *createdAtTime;

/// Type to identify the message is sent by logged-in user or message is received.
///
/// Message type are:
///
/// `AL_OUT_BOX`: To know the message is sent by a logged-in user.
///
/// `AL_IN_BOX` : To know the message is received type.
@property (nonatomic, copy) NSString *type;

/// Sets or gets the source type used for identifying the request came from which platform.
///
/// This are types of source:
/// WEB = 1,
/// ANDROID = 2,
/// IOS = 3
@property (nonatomic) short source;

/// Same as `to`
@property (nonatomic, copy) NSString *contactIds;

/// :nodoc:
@property (nonatomic, assign) BOOL storeOnDevice;

/// `ALFileMetaInfo` will have details currently uploaded or download file.
@property (nonatomic,retain) ALFileMetaInfo *fileMeta;

/// Name of file which is stored on disk.
@property (nonatomic,retain) NSString *imageFilePath;

/// Used for the set or get the current attachment upload is in progress or not.
@property (nonatomic,assign) BOOL inProgress;

/// :nodoc:
@property (nonatomic, strong) NSString *fileMetaKey;

/// Upload is failed in attachment
@property (nonatomic, assign) BOOL isUploadFailed;

/// For internal use only.
@property (nonatomic,assign) BOOL delivered;

/// To know if message is sent successfully.
@property(nonatomic,assign) BOOL sentToServer;

/// :nodoc:
@property(nonatomic,copy) NSManagedObjectID *msgDBObjectId;

/// Paired message key is used for marking the single message as read.
@property(nonatomic,copy) NSString *pairedMessageKey;

/// :nodoc:
@property(nonatomic,retain) NSString *applicationId;

/// Used to set or get the content of the message.
///
/// The content type are :
///
/// * `ALMESSAGE_CONTENT_DEFAULT`
/// * `ALMESSAGE_CONTENT_ATTACHMENT`
/// * `ALMESSAGE_CONTENT_LOCATION`
/// * `ALMESSAGE_CONTENT_TEXT_HTML`
/// * `ALMESSAGE_CONTENT_VCARD`
/// * `ALMESSAGE_CONTENT_AUDIO`
/// * `ALMESSAGE_CONTENT_CAMERA_RECORDING`
/// * `ALMESSAGE_CHANNEL_NOTIFICATION`
@property(nonatomic) short contentType;

/// Channel key or groupId which is linked to `ALChanel` object.
///
/// If groupId is not nil then its Channel message otherwise it's the one-to-one message.
@property (nonatomic, copy) NSNumber *groupId;

/// Conversation id for context based chat
@property(nonatomic,copy) NSNumber *conversationId;

/// Gets the status types to know the current message status.
///
/// Type of status are:
///
/// * SENT = 3,
/// * DELIVERED = 4,
/// * DELIVERED_AND_READ = 5,
@property (nonatomic, copy) NSNumber *status;

/// Returns or sets key-value dictionary of message metadata otherwise nil.
@property (nonatomic,retain) NSMutableDictionary *metadata;

/// Returns or sets reply type of message see `-[ALMessage getReplyType:]`.
@property (nonatomic,copy) NSNumber *messageReplyType;

/// Returns YES if the stored message has been deleted otherwise, NO.
@property (nonatomic,assign) BOOL deleted;

/// :nodoc:
@property (nonatomic, assign) BOOL msgHidden;

/// Returns formated date or time string to display in the recent chat conversation.
///
/// You need to compare the current date and the created at the time of message to know that is the message is for today.
/// @param today YES in case of the current day is today otherwise pass NO.
- (NSString *)getCreatedAtTime:(BOOL)today;

/// Gets the `ALMessage` for given dictionary.
/// @param messageDictonary An dictionary of message data.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// Returns YES if attachment download is needed otherwise NO.
- (BOOL)isDownloadRequired;

/// Returns YES if the attachment upload retry is required or not.
- (BOOL)isUploadRequire;

/// Returns YES if the message is hidden and won't be shown in chat otherwise NO.
- (BOOL)isHiddenMessage;

/// Returns YES if the Message is for audio-video call hidden notification otherwise NO.
- (BOOL)isVOIPNotificationMessage;

/// Gets the formated string date of created at the time for given today flag.
///
/// You need to compare the current date and the created time of the message to know that is the message is for today.
/// @param today YES in case of the current day is today otherwise pass NO.
- (NSString *)getCreatedAtTimeChat:(BOOL)today;

/// Returns the channel key or group of the message.
- (NSNumber *)getGroupId;

/// Returns the text for message to show in notification based on `contentType` of `ALMessage`
- (NSString *)getLastMessage;

/// Gets the Message metadata for given JSON metadata string.
/// @param string JSON string of the metadata.
- (NSMutableDictionary *)getMetaDataDictionary:(NSString *)string;

/// Gets the Audio video call action text to show in chat.
- (NSString *)getVOIPMessageText;

/// Returns YES if the `ALMessage` object is hidden message otherwise NO.
- (BOOL)isMsgHidden;

/// :nodoc:
- (BOOL)isPushNotificationMessage;

/// :nodoc:
- (BOOL)isMessageCategoryHidden;

/// Gets the current reply type of the message.
///
/// Used to know if the message has replied or reply message is a hidden or normal message.
- (ALReplyType)getReplyType;

/// :nodoc:
- (BOOL)isToIgnoreUnreadCountIncrement;

/// Returns YES if the message is of type reply in chat conversation otherwise NO.
- (BOOL)isAReplyMessage;

/// Returns YES in case of the message is sent by the logged-in user in chat otherwise NO.
- (BOOL)isSentMessage;

/// Returns YES if the message is received type otherwise NO.
- (BOOL)isReceivedMessage;

/// Returns YES in case of Message is location content type otherwise NO.
- (BOOL)isLocationMessage;

/// Returns YES in case of the message is of contact attachment content type otherwise NO.
- (BOOL)isContactMessage;

/// Returns YES in case of message is channel action type.
/// Example : Message are action type channel added, removed, updated, left, changed name of channel.
- (BOOL)isChannelContentTypeMessage;

/// Returns YES in case of the message is document type otherwise NO.
- (BOOL)isDocumentMessage;

/// Returns YES in case of the message is silent notification this is used in channel conversation otherwise NO.
- (BOOL)isSilentNotification;

/// Returns YES in case of the message is deleted for all the users in Channel.
- (BOOL)isDeletedForAll;

/// :nodoc:
- (BOOL)isMessageSentToServer;

/// Gets the `ALMessage` object with default data for given `ALMessageBuilder` object.
/// @param builder Create the `ALMessageBuilder` for one-to-one or channel conversation.
- (instancetype)initWithBuilder:(ALMessageBuilder *)builder;

/// Gets the `ALMessage` object with default data build using the `ALMessageBuilder` object.
/// @param builder `ALMessageBuilder` object is used for creating `ALMessage` with easy and limited data.
+ (instancetype)build:(void (^)(ALMessageBuilder *))builder;

/// Used for identifying the message notification is disabled or enabled.
/// @return Returns YES in case of message notification has been disabled otherwise, NO message notifications are enabled.
- (BOOL)isNotificationDisabled;

/// :nodoc:
- (BOOL)isLinkMessage;

/// Returns YES if the message is to reset the unread count of conversation otherwise NO.
- (BOOL)isResetUnreadCountMessage;

/// Returns YES if the message has an attachment otherwise, NO in case of the text message.
- (BOOL)hasAttachment;

/// Sets the deleted flag in message metadata.
- (void)setAsDeletedForAll;

/// Combines key-value metadata and returns the message metadata.
/// @param messageMetadata Metadata to combine with message metadata.
- (NSMutableDictionary *)combineMetadata:(NSMutableDictionary *)messageMetadata;
@end
