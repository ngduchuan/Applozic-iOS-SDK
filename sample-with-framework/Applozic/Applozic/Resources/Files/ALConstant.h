//
//  ALConstant.h
//  ChatApp
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALUserDefaultsHandler.h"

#define APPLOZIC_SDK_VERSION @"4.0.2"

#define KBASE_URL ([ALUserDefaultsHandler getBASEURL])
#define MQTT_URL ([ALUserDefaultsHandler getMQTTURL])
#define KBASE_FILE_URL ([ALUserDefaultsHandler getFILEURL])
#define MQTT_PORT ([ALUserDefaultsHandler getMQTTPort])

#define GREY_COLOR ([UIColor colorWithWhite:0.7 alpha:0.1])
#define TEXT_VIEW_TO_MESSAGE_VIEW_RATIO 1.4 // Proper scolling.... 

#define FORWARD_STATUS @"5"
#define REPLIED_STATUS @"4"
#define DEFAULT_FONT_NAME @"Helvetica-Bold"

#define APPLOZIC_TOPBAR_COLOR @"ApplozicTopbarColor"
#define APPLOZIC_CHAT_BACKGROUND_COLOR @"ApplozicChatBackgroundColor"
#define APPLOZIC_CHAT_FONTNAME @"ApplozicChatFontName"
#define APPLOGIC_TOPBAR_TITLE_COLOR @"ApplozicTopbarTitleColor"
#define APPLOGIC_IMAGEDOWNLOAD_BASEURL @"https://applozic.appspot.com/rest/ws/file"

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
#define IS_OS_EARLIER_THAN_10 ([[[UIDevice currentDevice] systemVersion] floatValue] < 10.0)

#define CONNECTION_TYPE_USER_IMG_UPLOAD @"CONNECTION_TYPE_USER_IMG_UPLOAD"
#define CONNECTION_TYPE_GROUP_IMG_UPLOAD @"CONNECTION_TYPE_GROUP_UPLOAD"
#define IMAGE_UPLOAD_URL @"/rest/ws/upload/file"
#define IMAGE_UPLOAD_ENDPOINT @"/files/upload/"
#define CUSTOM_STORAGE_IMAGE_UPLOAD_ENDPOINT @"/rest/ws/upload/image?aclsPrivate=true"
#define GOOGLE_CLOUD_STORAGE_IMAGE_UPLOAD_ENDPOINT @"/rest/ws/upload/image"
#define IMAGE_THUMBNAIL_ENDPOIT @"/files/"
#define IMAGE_DOWNLOAD_ENDPOINT @"/files/get/"
#define AL_EMPTY_JSON_STRING @"\"EMPTY_LIST\""


#define SOURCE_IOS 3

typedef enum {
    //outbox
    SENT = 3,
    DELIVERED = 4,
    DELIVERED_AND_READ = 5,

    //inbox
    PENDING = 2,
    UNREAD = 0,
    READ = 1
} MessageStatus;

// USER TYPE FOR INTERNAL USE

typedef enum {
    ALBOT  = 1,
    ALAPPLICATION_ADMIN =   2,
    ALUSER_ROLE  =  3,
    ALADMIN_ROLE  = 4,
    ALBUSINESS =  5,
    ALAPPLICATION_BROADCASTER =  6,
    ALSUPPORT  = 7,
    ALAPPLICATION_WEB_ADMIN =8
} ALUSER_ROLE_TYPE;


typedef enum {
    APP_STATE_BACKGROUND = -1,
    APP_STATE_INACTIVE   = 0,
    APP_STATE_ACTIVE     = 1
} APP_TRI_STATE;

typedef enum {
    ALNOTIFICATION_ENABLE_SOUND = 0,
    ALNOTIFICATION_DISABLE_SOUND = 1,
    ALNOTIFICATION_ENABLE = 0,
    ALNOTIFICATION_DISABLE = 2
} ALNOTIFICATION_TYPE_MODE;

typedef enum {
    
    ALCLOSED = -1,
    ALBETA = 0,
    ALSTARTER = 1,
    ALLAUNCH = 2,
    ALGROWTH = 3,
    ALENTERPRISE = 4,
    ALSUSPENDED = 6
} ALPRICING_PACKAGE;
