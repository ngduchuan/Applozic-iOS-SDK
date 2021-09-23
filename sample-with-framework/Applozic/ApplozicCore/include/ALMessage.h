//
//  ALMessage.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/NSManagedObject.h>
#import "ALJson.h"
#import "ALFileMetaInfo.h"
#import "ALApplozicSettings.h"
#import "ALMessageBuilder.h"
#import "ALConstant.h"

/// Default message content type for text messages.
static int const ALMESSAGE_CONTENT_DEFAULT = 0;

/// This message content type is used for attachment messages.
static int const ALMESSAGE_CONTENT_ATTACHMENT = 1;

/// This message content type is used for location messages.
static int const ALMESSAGE_CONTENT_LOCATION = 2;

/// This message content type is used for Rich and HTML messages.
static int const ALMESSAGE_CONTENT_TEXT_HTML = 3;

/// :nodoc:
static int const ALMESSAGE_CONTENT_PRICE = 4;

/// :nodoc:
static int const ALMESSAGE_CONTENT_TEXT_URL = 5;

/// This message content type is used for contact attachment.
static int const ALMESSAGE_CONTENT_VCARD = 7;

/// This message content type is used for audio attachment.
static int const ALMESSAGE_CONTENT_AUDIO = 8;

/// This message content type is used for video attachment.
static int const ALMESSAGE_CONTENT_CAMERA_RECORDING = 9;

/// This message content type is used for channel action.
static int const ALMESSAGE_CHANNEL_NOTIFICATION = 10;

/// :nodoc:
static int const ALMESSAGE_CONTENT_CUSTOM = 101;

/// :nodoc:
static int const ALMESSAGE_CONTENT_HIDDEN = 11;

/// :nodoc:
static NSString *const AL_CATEGORY_PUSHNNOTIFICATION = @"PUSHNOTIFICATION";
/// :nodoc:
static NSString *const AL_CATEGORY_HIDDEN = @"HIDDEN";

static NSString *const AL_MESSAGE_REPLY_KEY = @"AL_REPLY";

/// Sent message type. The message is sent by logged-in user.
static NSString *const AL_OUT_BOX = @"5";

/// Received message type.
static NSString *const AL_IN_BOX = @"4";

/// :nodoc:
static NSString *const AL_RESET_UNREAD_COUNT = @"AL_RESET_UNREAD_COUNT";

typedef enum {
    AL_NOT_A_REPLY,
    AL_A_REPLY,
    AL_REPLY_BUT_HIDDEN,
}ALReplyType;

/// Description
@interface ALMessage : ALJson

/// Message key is unique identifying key for `ALMessage` object.
///
/// This message key is used in all the places related to Message for performing operation on Core Data.
@property (nonatomic, copy) NSString *key;

/// Device key is used on the server to identify from which device the message is sent in conversation.
@property (nonatomic, copy) NSString *deviceKey;

/// User primary key is used on server to identify from which user the message is sent in conversation.
@property (nonatomic, copy) NSString *userKey;

/// UserId of Receiver user currently sent a message in one-to-one or channel conversation.
@property (nonatomic, copy) NSString *to;

/// Text message.
@property (nonatomic, copy) NSString *message;

/// :nodoc:
@property (nonatomic, assign) BOOL sendToDevice;

/// :nodoc:
@property (nonatomic, assign) BOOL shared;

/// Created at time which is in milliseconds.
/// This will be useful for showing the time of the message sent or received in chat and also to load the older message based on the created at time.
@property (nonatomic, copy) NSNumber *createdAtTime;


/// Type to identify the message is sent by logged-in user or mesage is recieved.
///
@property (nonatomic, copy) NSString *type;


/// Description
@property (nonatomic) short source;


/// Description
@property (nonatomic, copy) NSString *contactIds;


/// :nodoc:
@property (nonatomic, assign) BOOL storeOnDevice;


/// Description
@property (nonatomic,retain) ALFileMetaInfo *fileMeta;

/// Name of file which is stored on disk.
@property (nonatomic,retain) NSString *imageFilePath;


/// Description
@property (nonatomic,assign) BOOL inProgress;


/// Description
@property (nonatomic, strong) NSString *fileMetaKey;


/// Description
@property (nonatomic, assign) BOOL isUploadFailed;


/// Description
@property (nonatomic,assign) BOOL delivered;


/// Description
@property(nonatomic,assign)BOOL sentToServer;


/// Description
@property(nonatomic,copy) NSManagedObjectID *msgDBObjectId;


/// Description
@property(nonatomic,copy) NSString *pairedMessageKey;


/// :nodoc:
@property(nonatomic,assign) long messageId;


/// Description
@property(nonatomic,retain) NSString *applicationId;


/// Description
@property(nonatomic) short contentType;

/// Description
@property (nonatomic, copy) NSNumber *groupId;

/// Description
@property(nonatomic,copy) NSNumber *conversationId;


/// Description
@property (nonatomic, copy) NSNumber *status;


/// Description
@property (nonatomic,retain) NSMutableDictionary *metadata;


/// Description
@property (nonatomic,copy) NSNumber *messageReplyType;


/// Description
@property (nonatomic,assign) BOOL deleted;


/// <#Description#>
@property (nonatomic, assign) BOOL msgHidden;

/// Description
/// @param today today description
- (NSString *)getCreatedAtTime:(BOOL)today;

/// Description
/// @param messageDictonary messageDictonary description
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// Description
- (BOOL)isDownloadRequired;

/// Description
- (BOOL)isUploadRequire;

/// Returns YES if the message is of hidden and wont be shown in chat.
- (BOOL)isHiddenMessage;

/// Returns YES if the Message is for audio video call hidden notification otherwise NO.
- (BOOL)isVOIPNotificationMessage;

/// Gets the formated string date of created at time for given today flag.
///
/// You need to compare the current date and the created at time of message to know that is the message is for today.
/// @param today YES in case of the current day is today otherwise pass NO.
- (NSString *)getCreatedAtTimeChat:(BOOL)today;

/// Returns the channel key or group of message.
- (NSNumber *)getGroupId;

/// Description
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
/// Used to know if the message has reply or reply message is hidden or normal message.
- (ALReplyType)getReplyType;

/// :nodoc:
- (BOOL)isToIgnoreUnreadCountIncrement;

/// Returns YES if the message is of type reply in chat conversation otherwise NO.
- (BOOL)isAReplyMessage;

/// Returns YES in case of message is sent by logged-in user in chat otherwise NO.
- (BOOL)isSentMessage;

/// Returns YES if the message is received type otherwise NO.
- (BOOL)isReceivedMessage;

/// Returns YES in case of Message is location content type otherwise NO.
- (BOOL)isLocationMessage;

/// Returns YES in case of message is of contact attachment content type otherwise NO.
- (BOOL)isContactMessage;

/// Returns YES in case of message is channel action type.
/// Example : Message are action type  channel added, removed, updated,  left, changed name of channel.
- (BOOL)isChannelContentTypeMessage;

/// Returns YES in case of message is document type otherwise NO.
- (BOOL)isDocumentMessage;

/// Returns YES in case of message is silent notification this is used in channel conversation otherwise NO.
- (BOOL)isSilentNotification;

/// Returns YES in case of message is deleted for all the users in Channel.
- (BOOL)isDeletedForAll;

/// Description
- (BOOL)isMessageSentToServer;

/// Gets the `ALMessage` object with default data for given  `ALMessageBuilder` object.
/// @param builder Create the `ALMessageBuilder` for one-to-one or channel conversation.
- (instancetype)initWithBuilder:(ALMessageBuilder *)builder;

/// Gets the `ALMessage` object with default data build using `ALMessageBuilder` object.
/// @param builder `ALMessageBuilder` object is used for creating `ALMessage` with easy and limited data.
+ (instancetype)build:(void (^)(ALMessageBuilder *))builder;

/// Used for identify the message notification is disabled or enabled.
/// @return Returns YES in case of message notification has been disabled otherwise, NO message notifications are enabled.
- (BOOL)isNotificationDisabled;

/// :nodoc:
- (BOOL)isLinkMessage;

/// Returns YES if the message is to reset the unread count of conversation otherwise NO.
- (BOOL)isResetUnreadCountMessage;

/// Returns YES if the message has an attachment otherwise, NO in case of text message.
- (BOOL)hasAttachment;

/// Sets the deleted flag in message metadata.
- (void)setAsDeletedForAll;

/// Combines key-value metadata and returns the message metadata.
/// @param messageMetadata Metadata to combine with message metadata.
- (NSMutableDictionary *)combineMetadata:(NSMutableDictionary *)messageMetadata;
@end
