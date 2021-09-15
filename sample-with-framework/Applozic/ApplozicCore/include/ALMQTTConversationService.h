//
//  ALMQTTConversationService.h
//  Applozic
//
//  Created by Applozic Inc on 11/27/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MQTTClient.h"
#import "ALMessage.h"
#import "ALUserDetail.h"
#import "ALSyncCallService.h"
#import "ALUserDetail.h"
#import "ALRealTimeUpdate.h"

extern NSString *const ALChannelDidChangeGroupMuteNotification;
extern NSString *const ALLoggedInUserDidChangeDeactivateNotification;

/// `ALMQTTConversationDelegate` protocol used for listening the real time updates from MQTT.
/// This is an internal class used for MQTT real-time update events.
@protocol ALMQTTConversationDelegate <NSObject>

/// This callback will be called once the new message is received.
/// @param alMessage This will have `ALMessage` object on new message received
/// @param messageArray This will be nil
- (void)syncCall:(ALMessage *)alMessage andMessageList:(NSMutableArray *)messageArray;

///
/// @param messageKey Will have messageKey for delivered status
/// @param contactId UserId of the user message delivered to.
/// @param status status description
- (void)delivered:(NSString *)messageKey contactId:(NSString *)contactId withStatus:(int)status;

/// Description
/// @param contactId <#contactId description#>
/// @param status <#status description#>
- (void)updateStatusForContact:(NSString *)contactId withStatus:(int)status;

/// <#Description#>
/// @param applicationKey <#applicationKey description#>
/// @param userId <#userId description#>
/// @param status <#status description#>
- (void)updateTypingStatus:(NSString *) applicationKey userId:(NSString *)userId status:(BOOL)status;

/// <#Description#>
/// @param alUserDetail <#alUserDetail description#>
- (void)updateLastSeenAtStatus:(ALUserDetail *)alUserDetail;

/// This method will be called once MQTT connection is closed.
- (void)mqttConnectionClosed;

@optional

/// This method will be called once the MQTT is connected.
- (void)mqttDidConnected;

/// This method is used for re
/// @param userId <#userId description#>
/// @param flag <#flag description#>
- (void)reloadDataForUserBlockNotification:(NSString *)userId andBlockFlag:(BOOL)flag;

/// <#Description#>
/// @param userId <#userId description#>
- (void)updateUserDetail:(NSString *)userId;

@end

/// `ALMQTTConversationService` this class is used for
@interface ALMQTTConversationService : NSObject <MQTTSessionDelegate>

/// <#Description#>
+(ALMQTTConversationService *)sharedInstance;

/// <#Description#>
@property (nonatomic, strong) ALSyncCallService *alSyncCallService;

/// <#Description#>
@property (nonatomic, weak) id<ALMQTTConversationDelegate>mqttConversationDelegate;

/// <#Description#>
@property (nonatomic, weak) id<ApplozicUpdatesDelegate>realTimeUpdate;

/// <#Description#>
@property (nonatomic, readwrite) MQTTSession *session;

/// This method is used for subscribing to real-time events for conversation.
- (void)subscribeToConversation;

/// This method is used for subscribing to real-time events for conversation with topic name.
/// @param topic Pass the name of the topic to subscribe.
- (void)subscribeToConversationWithTopic:(NSString *)topic;

/// This method is used for unsubscribing to real-time events for conversation.
- (void)unsubscribeToConversation;

/// This method is used for unsubscribing to real-time events for conversation with topic name.
/// @param topic Pass the name of the topic to unsubscribe.
- (void)unsubscribeToConversationWithTopic:(NSString *)topic;

/// This method is used for
/// @param userKey userKey description
- (BOOL)unsubscribeToConversation:(NSString *)userKey;

/// This method is used for sending a typing status in one-to-one or group/channel conversation.
/// @param applicationKey applicationKey description
/// @param userId Pass the receiver userId of the user.
/// @param channelKey Pass the channelKey of `ALChannel`.
/// @param typing If the logged user is typing pass YES or true in typing else on stop of user typing pass NO or false to stop the typing.
- (void)sendTypingStatus:(NSString *)applicationKey userID:(NSString *)userId andChannelKey:(NSNumber *)channelKey typing:(BOOL)typing;

/// This method is used for unsubscribe To Channel Conversation.
/// @param channelKey Pass the channelKey of `ALChannel`.
- (void)unSubscribeToChannelConversation:(NSNumber *)channelKey;

/// This method is used for subscribe to channel Conversation.
/// @param channelKey Pass the channelKey of `ALChannel`.
- (void)subscribeToChannelConversation:(NSNumber *)channelKey;

/// This method is used for subscribe To Open Channel.
/// @param channelKey Pass the channelKey of `ALChannel`.
- (void)subscribeToOpenChannel:(NSNumber *)channelKey;

/// This method is used for unsubscribe.
/// @param channelKey Pass the channelKey of f `ALChannel`.
- (void)unSubscribeToOpenChannel:(NSNumber *)channelKey;

/// Description
/// @param alMessage Pass the `ALMessage` object.
/// @param nsMutableDictionary Pass
- (void)syncReceivedMessage:(ALMessage *)alMessage withNSMutableDictionary:(NSMutableDictionary *)nsMutableDictionary;

/// This method used for subscribe To Conversation with topic.
/// @param topic Pass the name of topic to subscribe.
/// @param completion completion description
- (void)subscribeToConversationWithTopic:(NSString *)topic withCompletionHandler:(void (^)(BOOL subscribed, NSError *error))completion;

/// For publishing a read status of message using MQTT.
/// @param messageKey Pass the messageKey which is used for identifiying the message.
- (BOOL)messageReadStatusPublishWithMessageKey:(NSString *)messageKey;

/// For publishing custom data with topic using MQTT.
/// @param dataString Pass the string of data to publish.
/// @param topic Pass the topic name to publish on.
- (BOOL)publishCustomData:(NSString *)dataString withTopicName:(NSString *)topic;
@end
