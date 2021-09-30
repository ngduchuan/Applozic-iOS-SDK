//
//  ALRealTimeUpdate.h
//  Applozic
//
//  Created by Sunil on 08/03/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessage.h"
#import "ALUserDetail.h"
#import "ALChannel.h"

/// `ApplozicUpdatesDelegate` protocol is used for real time callback events for message, channel, user and typing.
@protocol ApplozicUpdatesDelegate <NSObject>

/// The callback will be called on the new message is received.
/// @param alMessage Will have `ALMessage` object which is recieved message.
- (void)onMessageReceived:(ALMessage *)alMessage;

/// The callback will be called on the message is sent by same user logged-in on different devices or platforms.
/// @param alMessage Will have ALMessage object which is sent message.
- (void)onMessageSent:(ALMessage *)alMessage;

/// The callback will be called on the user details updated like name, profile imageUrl, status etc.
/// @param userDetail Will have ALUserDetail object which will have user properties.
- (void)onUserDetailsUpdate:(ALUserDetail *)userDetail;

/// The callback will be called on message is delivered to receiver.
/// @param message Will have ALMessage object which is delivered message it has status.
- (void)onMessageDelivered:(ALMessage *)message;

/// The callback will be called on the message is deleted by same user logged-in on different devices or platforms.
/// @param messageKey Will have messageKey of message which is deleted.
- (void)onMessageDeleted:(NSString *)messageKey;

/// The callback will be called on the message is read and delivered to receiver user.
/// @param message Will have ALMessage object which is delivered and read.
/// @param userId Will have userId which is delivered and read a message.
- (void)onMessageDeliveredAndRead:(ALMessage *)message withUserId:(NSString *)userId;

/// The callback will be called on the conversation is deleted.
/// @param userId If the conversation is deleted for user then userId will be.
/// @param groupId If conversation is deleted for channel then groupId will be there its channelKey.
- (void)onConversationDelete:(NSString *)userId withGroupId:(NSNumber*)groupId;

/// The callback will be called on the conversation read by same user logged-in on different devices or platforms.
/// @param userId If conversation read for user then userId will be there else groupId will be their.
/// @param groupId If conversation raad for channel/group then channelKey will be there and userId will be nil.
- (void)conversationReadByCurrentUser:(NSString *)userId withGroupId:(NSNumber *)groupId;

/// The callback will be called on for typing events.
/// @param userId Will have user's userId who is typing.
/// @param status If status flag is YES or true then user started typing, if status is NO or false then user stop the typing.
- (void)onUpdateTypingStatus:(NSString *)userId status:(BOOL)status;

/// The callback will be called on the user online or offline update.
/// @param alUserDetail Will have ALUserDetail object of user.
- (void)onUpdateLastSeenAtStatus:(ALUserDetail *)alUserDetail;

/// The callback will be called on the user is blocked or unblocked.
/// @param userId Will have the user's userId blocked or unblocked.
/// @param flag If true or YES then user is blocked else false or NO then unblocked.
- (void)onUserBlockedOrUnBlocked:(NSString *)userId andBlockFlag:(BOOL)flag;

/// The callback will be called on if any updates on Channel.
/// @param channel It will have ALChannel object.
- (void)onChannelUpdated:(ALChannel *)channel;

/// The callback will be called on the receiver read the all messages in conversation.
/// @param userId Will have receiver userId who has read the conversation.
- (void)onAllMessagesRead:(NSString *)userId;

/// The callback will be called on MQTT disconnected you can resubscribe to conversation.
- (void)onMqttConnectionClosed;

/// The callback will be called on the MQTT is connected.
- (void)onMqttConnected;

/// ThThe callback will be called the user muted.
/// @param userDetail Will have ALUserDetail object.
- (void)onUserMuteStatus:(ALUserDetail *)userDetail;

/// The callback will be called after a group has been muted or unmuted.
/// @param channelKey You will get the channelKey by using this channel key you can get channel and check isNotificationMuted from ALChannel object.
- (void)onChannelMute:(NSNumber *)channelKey;

@end

/// `ALRealTimeUpdate` class is used for real time events for message, Channel, user, typing.
@interface ALRealTimeUpdate : NSObject

@end
