//
//  ALPushNotificationService.h
//  ChatApp
//
//  Created by devashish on 28/09/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

// NEW CODES FOR VERSION CODE 105...

static NSString *const APPLOZIC_PREFIX = @"APPLOZIC_";
static NSString *const APPLOZIC_CATEGORY_KEY = @"category";

typedef enum
{
    AL_SYNC = 0,
    AL_DELIVERED = 1,
    AL_DELETE_MESSAGE = 2,
    AL_CONVERSATION_DELETED = 3,
    AL_MESSAGE_READ = 4,
    AL_MESSAGE_DELIVERED_AND_READ = 5,
    AL_CONVERSATION_READ = 6,
    AL_CONVERSATION_DELIVERED_AND_READ = 7,
    AL_USER_CONNECTED = 8,
    AL_USER_DISCONNECTED = 9,
    AL_MESSAGE_SENT = 10,
    AL_USER_BLOCK = 11,
    AL_USER_UNBLOCK = 12,
    AL_TEST_NOTIFICATION = 13,
    AL_MTEXTER_USER = 14,
    AL_CONTACT_VERIFIED = 15,
    AL_DEVICE_CONTACT_SYNC = 16,
    AL_MT_EMAIL_VERIFIED = 17,
    AL_DEVICE_CONTACT_MESSAGE = 18,
    AL_CANCEL_CALL = 19,
    AL_MESSAGE = 20,
    AL_DELETE_MULTIPLE_MESSAGE = 21,
    AL_SYNC_PENDING = 22,
    AL_GROUP_CONVERSATION_READ = 23,
    AL_USER_MUTE_NOTIFICATION = 24,
    AL_USER_DETAIL_CHANGED = 25,
    AL_USER_DELETE_NOTIFICATION = 26,
    AL_GROUP_CONVERSATION_DELETED = 27,
    AL_CONVERSATION_DELETED_NEW = 28,
    AL_MESSAGE_METADATA_UPDATE = 29
} AL_PUSH_NOTIFICATION_TYPE;


#import <Foundation/Foundation.h>
#import "ALMessage.h"
#import "ALUserDetail.h"
#import "ALSyncCallService.h"
#import <Applozic/ALChatLauncher.h>
#import "ALMQTTConversationService.h"
#import "ALRealTimeUpdate.h"

@interface ALPushNotificationService : NSObject

-(BOOL) isApplozicNotification: (NSDictionary *) dictionary;

@property (nonatomic, weak) id<ApplozicUpdatesDelegate>realTimeUpdate;

-(BOOL) processPushNotification: (NSDictionary *) dictionary updateUI: (NSNumber*) updateUI;

@property(nonatomic,strong) ALSyncCallService * alSyncCallService;

@property(nonatomic, readonly, strong) UIViewController *topViewController;

@property(nonatomic,strong) ALChatLauncher * chatLauncher;

-(void)notificationArrivedToApplication:(UIApplication*)application withDictionary:(NSDictionary *)userInfo;
+(void)applicationEntersForeground;
+(void)userSync;
-(BOOL) checkForLaunchNotification:(NSDictionary *)dictionary;
+(NSString*) notificationType:(AL_PUSH_NOTIFICATION_TYPE)type;
@end
