//
//  ALPushNotificationService.h
//  ChatApp
//
//  Created by devashish on 28/09/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

// NEW CODES FOR VERSION CODE 105...

static NSString *const MT_SYNC = @"APPLOZIC_01";
static NSString *const MT_DELIVERED = @"APPLOZIC_04";
static NSString *const MT_DELETE_MESSAGE = @"APPLOZIC_05";
static NSString *const MT_CONVERSATION_DELETED = @"APPLOZIC_06";
static NSString *const MT_MESSAGE_READ = @"APPLOZIC_07";
static NSString *const MT_MESSAGE_DELIVERED_AND_READ = @"APPLOZIC_08";
static NSString *const MT_CONVERSATION_READ = @"APPLOZIC_09";
static NSString *const MT_CONVERSATION_DELIVERED_AND_READ = @"APPLOZIC_10";
static NSString *const ALUSER_CONNECTED = @"APPLOZIC_11";
static NSString *const ALUSER_DISCONNECTED = @"APPLOZIC_12";
static NSString *const MT_MESSAGE_SENT = @"APPLOZIC_02";
static NSString *const MT_USER_BLOCK = @"APPLOZIC_16";
static NSString *const MT_USER_UNBLOCK = @"APPLOZIC_17";
static NSString *const TEST_NOTIFICATION = @"APPLOZIC_20";
static NSString *const MTEXTER_USER = @"MTEXTER_USER";
static NSString *const MT_CONTACT_VERIFIED = @"MT_CONTACT_VERIFIED";
static NSString *const MT_DEVICE_CONTACT_SYNC = @"MT_DEVICE_CONTACT_SYNC";
static NSString *const MT_EMAIL_VERIFIED = @"MT_EMAIL_VERIFIED";
static NSString *const MT_DEVICE_CONTACT_MESSAGE = @"MT_DEVICE_CONTACT_MESSAGE";
static NSString *const MT_CANCEL_CALL = @"MT_CANCEL_CALL";
static NSString *const MT_MESSAGE = @"MT_MESSAGE";
static NSString *const MT_DELETE_MULTIPLE_MESSAGE = @"MT_DELETE_MULTIPLE_MESSAGE";
static NSString *const MT_SYNC_PENDING = @"MT_SYNC_PENDING";
static NSString *const APPLOZIC_PREFIX = @"APPLOZIC_";
static NSString *const APPLOZIC_CATEGORY_KEY = @"category";

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
@end
