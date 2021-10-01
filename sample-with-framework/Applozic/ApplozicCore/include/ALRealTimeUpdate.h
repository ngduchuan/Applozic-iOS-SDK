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

/// `ApplozicUpdatesDelegate` protocol is used for real-time callback events for the message, channel, user, and typing.
///
/// The `ApplozicUpdatesDelegate` is set only from `-[ApplozicClient initWithApplicationKey:withDelegate:]` method for update events.
@protocol ApplozicUpdatesDelegate <NSObject>

/// The callback will be called on the new message is received for logged in user.
/// @param alMessage An `ALMessage` object which is received message.
- (void)onMessageReceived:(ALMessage *)alMessage;

/// The callback will be called on the message is sent by the logged in user.
/// @param alMessage An `ALMessage` object which is sent message.
- (void)onMessageSent:(ALMessage *)alMessage;

/// The callback will be called on the user details updated like name, profile image URL, status, etc.
/// @param userDetail An `ALUserDetail ` object which will have receiver user properties.
- (void)onUserDetailsUpdate:(ALUserDetail *)userDetail;

/// The callback will be called on message is delivered to the receiver.
/// @param message An `ALMessage` object which has `status` that is `DELIVERED.
- (void)onMessageDelivered:(ALMessage *)message;

/// The callback will be called on the message is deleted by the same user logged in on different devices or platforms.
/// @param messageKey An message key of the deleted Message.
- (void)onMessageDeleted:(NSString *)messageKey;

/// The callback will be called on the message is read and delivered to the receiver user.
/// @param message An `ALMessage` object which has `status` that are `DELIVERED` or `DELIVERED_AND_READ`.
/// @param userId An receiver userId which is delivered and read of a message.
- (void)onMessageDeliveredAndRead:(ALMessage *)message withUserId:(NSString *)userId;

/// The callback will be called on the conversation is deleted for one-to-one or channel.
/// @param userId If the conversation is deleted for the receiver user the userId non nil otherwise nil.
/// @param groupId If the conversation is deleted for the channel the channel key will be non nil otherwise nil.
- (void)onConversationDelete:(NSString *)userId withGroupId:(NSNumber *)groupId;

/// The callback will be called on the conversation read by the same user logged in on different devices or platforms.
/// @param userId If the conversation is read for the user then userId will be non nil otherwise nil.
/// @param groupId If conversation raad for channel or group then channel key will be non nil otherwise nil.
- (void)conversationReadByCurrentUser:(NSString *)userId withGroupId:(NSNumber *)groupId;

/// The callback will be called on typing status update.
/// @param userId It will have receiver userId typing started or stoped..
/// @param status YES for the user started typing, if the status is NO then the user stops typing.
- (void)onUpdateTypingStatus:(NSString *)userId status:(BOOL)status;

/// The callback will be called on the user online or offline update.
/// @param alUserDetail An `ALUserDetail` object of user.
- (void)onUpdateLastSeenAtStatus:(ALUserDetail *)alUserDetail;

/// The callback will be called on the user is blocked or unblocked.
/// @param userId Receiver userId blocked or unblocked.
/// @param flag if YES then user is blocked otherwise unblocked for NO.
- (void)onUserBlockedOrUnBlocked:(NSString *)userId andBlockFlag:(BOOL)flag;

/// The callback will be called on if any updates on Channel.
/// @param channel It will have an updated `ALChannel` object.
- (void)onChannelUpdated:(ALChannel *)channel;

/// The callback will be called on the receiver read the all messages in the conversation.
/// @param userId An receiver userId who has read the conversation.
- (void)onAllMessagesRead:(NSString *)userId;

/// The callback will be called on MQTT disconnected you can resubscribe to the conversation.
- (void)onMqttConnectionClosed;

/// The callback will be called on the MQTT is connected.
- (void)onMqttConnected;

/// The callback will be called the user muted.
/// @param userDetail Will have `ALUserDetail` object.
- (void)onUserMuteStatus:(ALUserDetail *)userDetail;

/// The callback will be called after a group has muted for logged in user.
/// @param channelKey You will get the channel key by using this channel key you can get the channel and check isNotificationMuted from `ALChannel` object.
- (void)onChannelMute:(NSNumber *)channelKey;

@end

/// `ALRealTimeUpdate` class is used for real time events for message, Channel, user and typing.
@interface ALRealTimeUpdate : NSObject

@end
