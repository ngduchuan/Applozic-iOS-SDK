//
//  ALMQTTConversationService.h
//  Applozic
//
//  Created by Applozic Inc on 11/27/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALMessage.h"
#import "ALRealTimeUpdate.h"
#import "ALSyncCallService.h"
#import "ALUserDetail.h"
#import "MQTTClient.h"
#import <Foundation/Foundation.h>

/// Notification name for channel mute or unmuted.
extern NSString *const ALChannelDidChangeGroupMuteNotification;

/// Notification name for logged in user activated or deactivated.
extern NSString *const ALLoggedInUserDidChangeDeactivateNotification;

/// `ALMQTTConversationDelegate` protocol used for listening to the real-time updates from MQTT.
///
/// @warning This is used for MQTT real-time update events for internal purposes only.
@protocol ALMQTTConversationDelegate <NSObject>

/// This callback will be called once the new message is received.
///
/// @param alMessage This will have `ALMessage` object on new message received
/// @param messageArray This will be nil
- (void)syncCall:(ALMessage *)alMessage andMessageList:(NSMutableArray *)messageArray;

/// The callback will be called on message is delivered to the receiver.
///
/// @param messageKey Will have messageKey for delivered status
/// @param contactId UserId of the user message delivered to.
/// @param status Status are `DELIVERED` or `DELIVERED_AND_READ`.
- (void)delivered:(NSString *)messageKey contactId:(NSString *)contactId withStatus:(int)status;

/// The callback will be called on the receiver to read the all messages in the conversation.
///
/// @param contactId Will have receiver userId who has read the conversation.
/// @param status Read sttaus of message.
- (void)updateStatusForContact:(NSString *)contactId withStatus:(int)status;

/// The callback will be called on for typing events.
///
/// @param applicationKey App-ID of Applozic.
/// @param userId Will have user's userId who is typing.
/// @param status If the status flag is YES or true then the user started typing, if the status is NO or false then the user stops typing
- (void)updateTypingStatus:(NSString *) applicationKey userId:(NSString *)userId status:(BOOL)status;

/// The callback will be called on the user's online or offline update.
///
/// @param alUserDetail Will have `ALUserDetail` object of user.
- (void)updateLastSeenAtStatus:(ALUserDetail *)alUserDetail;

/// The callback will be called on MQTT disconnected you can resubscribe to the conversation.
- (void)mqttConnectionClosed;

@optional

/// The callback will be called on the MQTT is connected.
- (void)mqttDidConnected;

/// The callback will be called on the user is blocked or unblocked
/// @param userId Receiver userId blocked or unblocked.
/// @param flag if YES then user is blocked otherwise unblocked for NO.
- (void)reloadDataForUserBlockNotification:(NSString *)userId andBlockFlag:(BOOL)flag;

/// The callback will be called on the user details updated like name, profile image URL, status, etc.
/// @param userId Receiver userId the user details updated.
- (void)updateUserDetail:(NSString *)userId;

@end

/// `ALMQTTConversationService` used for making a connection to the server for real-time update events on MQTT.
///
/// @warning `ALMQTTConversationService` used for internal purposes only.
@interface ALMQTTConversationService : NSObject <MQTTSessionDelegate>

/// `ALMQTTConversationService` instance method.
+(ALMQTTConversationService *)sharedInstance;

/// `ALSyncCallService` instance method.
@property (nonatomic, strong) ALSyncCallService *alSyncCallService;

/// Sets the `ALMQTTConversationDelegate` for listening to the real-time updates from MQTT.
@property (nonatomic, weak) id<ALMQTTConversationDelegate>mqttConversationDelegate;

/// Gives callbacks for real-time update events for Messages, channels, Users, and Typing
@property (nonatomic, weak) id<ApplozicUpdatesDelegate>realTimeUpdate;

/// `MQTTSession` instance method.
@property (nonatomic, readwrite) MQTTSession *session;

/// Used for subscribing to real-time events for conversation.
- (void)subscribeToConversation;

/// Used for subscribing to real-time events for conversation with topic name.
/// @param topic Pass the name of the topic to subscribe.
- (void)subscribeToConversationWithTopic:(NSString *)topic;

/// Used for unsubscribing to real-time events for conversation.
- (void)unsubscribeToConversation;

/// Used for unsubscribing to real-time events for conversation with topic name.
/// @param topic Pass the name of the topic to unsubscribe.
- (void)unsubscribeToConversationWithTopic:(NSString *)topic;

/// Unsubscribe for all real-time update events for conversations.
/// @param userKey Pass the `[ALUserDefaultsHandler getUserKeyString];` key.
- (BOOL)unsubscribeToConversation:(NSString *)userKey;

/// Used for sending a typing status in one-to-one or channel conversation.
/// @param applicationKey App-Id or application key of Applozic.
/// @param userId Pass the receiver userId of the user.
/// @param channelKey Pass the channelKey of `ALChannel`.
/// @param typing If the logged user is typing pass YES or true in typing else on stop of user typing pass NO or false to stop the typing.
- (void)sendTypingStatus:(NSString *)applicationKey userID:(NSString *)userId andChannelKey:(NSNumber *)channelKey typing:(BOOL)typing;

/// Unsubscribe to typing status of channel conversation.
/// @param channelKey Pass the channelKey of `ALChannel`.
- (void)unSubscribeToChannelConversation:(NSNumber *)channelKey;

/// Subscribes to typing status for given channel key.
/// @param channelKey Pass the channelKey of `ALChannel`.
- (void)subscribeToChannelConversation:(NSNumber *)channelKey;

/// Subscribes to Open Channel for real-time update events.
/// @param channelKey Pass the channelKey of `ALChannel`.
- (void)subscribeToOpenChannel:(NSNumber *)channelKey;

/// Unsubscribes to open channel all real-time update events.
/// @param channelKey Pass the channelKey of f `ALChannel`.
- (void)unSubscribeToOpenChannel:(NSNumber *)channelKey;

/// Syncs the message and post an notification request, used for internal purposes only .
/// @param message Pass the `ALMessage` object.
/// @param notificationDictionary Notification dictionary.
- (void)syncReceivedMessage:(ALMessage *)message withNSMutableDictionary:(NSMutableDictionary *)notificationDictionary;

/// Used for subscribe to conversation with topic.
/// @param topic Pass the name of topic to subscribe.
/// @param completion completion YES in case of subscribed otherwise NO with an error.
- (void)subscribeToConversationWithTopic:(NSString *)topic withCompletionHandler:(void (^)(BOOL subscribed, NSError *error))completion;

/// For publishing a read status of the message using MQTT.
/// @param messageKey Pass the message key which is used for identifying the message.
- (BOOL)messageReadStatusPublishWithMessageKey:(NSString *)messageKey;

/// For publishing custom data with topic using MQTT.
/// @param dataString Pass the string of data to publish.
/// @param topic Pass the topic name to publish on.
- (BOOL)publishCustomData:(NSString *)dataString withTopicName:(NSString *)topic;
@end
