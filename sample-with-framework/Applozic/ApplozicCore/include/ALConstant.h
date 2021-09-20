//
//  ALConstant.h
//  ChatApp
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALUserDefaultsHandler.h"

#define KBASE_URL ([ALUserDefaultsHandler getBASEURL])
#define MQTT_URL ([ALUserDefaultsHandler getMQTTURL])
#define KBASE_FILE_URL ([ALUserDefaultsHandler getFILEURL])
#define MQTT_PORT ([ALUserDefaultsHandler getMQTTPort])

static NSString *const APPLOZIC_TOPBAR_COLOR = @"ApplozicTopbarColor";
static NSString *const APPLOZIC_CHAT_BACKGROUND_COLOR = @"ApplozicChatBackgroundColor";
static NSString *const APPLOZIC_CHAT_FONTNAME = @"ApplozicChatFontName";
static NSString *const APPLOGIC_TOPBAR_TITLE_COLOR = @"ApplozicTopbarTitleColor";
static NSString *const APPLOGIC_IMAGEDOWNLOAD_BASEURL = @"https://applozic.appspot.com/rest/ws/file";

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && (MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 568.0) && ((IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale) || !IS_OS_8_OR_LATER))
#define IS_STANDARD_IPHONE_6 (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 667.0  && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale)
#define IS_ZOOMED_IPHONE_6 (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 568.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale > [UIScreen mainScreen].scale)
#define IS_STANDARD_IPHONE_6_PLUS (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 736.0)
#define IS_ZOOMED_IPHONE_6_PLUS (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 375.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale < [UIScreen mainScreen].scale)
#define IS_IPHONE_6 (IS_STANDARD_IPHONE_6 || IS_ZOOMED_IPHONE_6)
#define IS_IPHONE_6_PLUS (IS_STANDARD_IPHONE_6_PLUS || IS_ZOOMED_IPHONE_6_PLUS)
#define IS_OS_9_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

static NSString *const AL_IMAGE_UPLOAD_URL = @"/rest/ws/upload/file";
static NSString *const AL_IMAGE_UPLOAD_ENDPOINT = @"/files/upload/";
static NSString *const AL_CUSTOM_STORAGE_IMAGE_UPLOAD_ENDPOINT = @"/rest/ws/upload/image?aclsPrivate=true";
static NSString *const AL_GOOGLE_CLOUD_STORAGE_IMAGE_UPLOAD_ENDPOINT = @"/rest/ws/upload/image";
static NSString *const AL_IMAGE_THUMBNAIL_ENDPOIT = @"/files/";
static NSString *const AL_IMAGE_DOWNLOAD_ENDPOINT = @"/files/get/";
static NSString *const AL_EMPTY_JSON_STRING = @"\"EMPTY_LIST\"";
static int const AL_SOURCE_IOS = 3;

/// Message status types for identifying the messgae is delivered, read and delivered, sent.
/// It has outbox type status for sent message and inbox type status for received message.
typedef enum {
    /// OUTBOX types
    /// Sent message type
    SENT = 3,
    /// Message which is sent in chat has been delivered.
    DELIVERED = 4,
    /// Message which is sent in chat has been delivered and read.
    DELIVERED_AND_READ = 5,

    /// INBOX types
    /// :nodoc:
    PENDING = 2,
    /// :nodoc:
    UNREAD = 0,
    /// :nodoc:
    READ = 1
} MessageStatus;

/// User type for internal use for identifying the type of user is login.
typedef enum {
    /// Bot type user.
    AL_BOT  = 1,
    /// Main Admin of the application.
    AL_APPLICATION_ADMIN =   2,
    /// Chat user in app.
    AL_USER_ROLE  =  3,
    /// Admin of application AppId.
    AL_ADMIN_ROLE  = 4,
    /// Business user of application.
    AL_BUSINESS =  5,
    /// Business user of application.
    AL_APPLICATION_BROADCASTER =  6,
    /// Support user of application.
    AL_SUPPORT  = 7,
    /// Dashboard admin of application.
    AL_APPLICATION_WEB_ADMIN =8
} ALUSER_ROLE_TYPE;

/// App state flags for identifying the notification is from background, active or inactive state.
typedef enum {
    /// App state is background.
    APP_STATE_BACKGROUND = -1,
    /// App state is inactive.
    APP_STATE_INACTIVE   = 0,
    /// App state is active.
    APP_STATE_ACTIVE     = 1
} APP_TRI_STATE;

/// User notification type is used for identifying the logged-in user notification is disabled, enabled, disable sound, enable the sound in APNs notification.
typedef enum {
    /// Enables the APN's notification sound.
    AL_NOTIFICATION_ENABLE_SOUND = 0,
    /// Disable the APN's notification sound.
    AL_NOTIFICATION_DISABLE_SOUND = 1,
    /// Enable the notifications.
    AL_NOTIFICATION_ENABLE = 0,
    /// Dsiable the notifications.
    AL_NOTIFICATION_DISABLE = 2
} AL_NOTIFICATION_TYPE_MODE;

/// Pricing package type for identifying the App-ID is in which pricing package it is using currently.
typedef enum {
    /// APP-ID is closed then the Pricing will be -1.
    AL_CLOSED = -1,
    /// APP-ID is beta then the Pricing will be 0.
    AL_BETA = 0,
    /// APP-ID is starter plan then the Pricing will be 1.
    AL_STARTER = 1,
    /// APP-ID is launch plan then the Pricing will be 2.
    AL_LAUNCH = 2,
    /// APP-ID is growth plan then the Pricing will be 3.
    AL_GROWTH = 3,
    /// APP-ID is enterprise plan then the Pricing will be 4.
    AL_ENTERPRISE = 4,
    /// APP-ID is suspended plan then the Pricing will be 6.
    AL_SUSPENDED = 6
} AL_PRICING_PACKAGE;

/// This call content type are for identifying call message notification is hidden or will show in chat.
/// 102 (Notification Only).
/// 103 (Show Message Content in chat).
typedef enum {
    /// Call notification where message is hidden in chat.
    AV_CALL_HIDDEN_NOTIFICATION = 102,
    /// Call message which will be disaplyed in chat.
    AV_CALL_MESSAGE = 103
} CALL_CONTENT_TYPE;
