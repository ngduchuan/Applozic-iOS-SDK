//
//  MqttConversationDelegateObjectMock.m
//  applozicdemoTests
//
//  Created by Mukesh on 26/12/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "MqttConversationDelegateObjectMock.h"

@implementation MqttConversationDelegateObjectMock

-(void)syncCall:(ALMessage *) alMessage andMessageList:(NSMutableArray*)messageArray {
}

-(void)delivered:(NSString *)messageKey contactId:(NSString *)contactId withStatus:(int)status {
}

-(void)updateStatusForContact:(NSString *)contactId withStatus:(int)status {
}

-(void)mqttDidConnected {
}

-(void)mqttConnectionClosed {}

-(void)updateTypingStatus:(NSString *)applicationKey userId:(NSString *)userId status:(BOOL)status {}

-(void)updateLastSeenAtStatus:(ALUserDetail *)alUserDetail {}

- (void)conversationReadByCurrentUser:(NSString *)userId withGroupId:(NSNumber *)groupId
{
}

- (void)onAllMessagesRead:(NSString *)userId {
}

- (void)onChannelUpdated:(ALChannel *)channel {
}

- (void)onConversationDelete:(NSString *)userId withGroupId:(NSNumber *)groupId {
}

- (void)onMessageDeleted:(NSString *)messageKey {
}

- (void)onMessageDelivered:(ALMessage *)message {
}

- (void)onMessageDeliveredAndRead:(ALMessage *)message withUserId:(NSString *)userId {
}

- (void)onMessageReceived:(ALMessage *)alMessage {
}

- (void)onMessageSent:(ALMessage *)alMessage {
}

- (void)onMqttConnected {
}

- (void)onMqttConnectionClosed {
}

- (void)onUpdateLastSeenAtStatus:(ALUserDetail *)alUserDetail {
}

- (void)onUpdateTypingStatus:(NSString *)userId status:(BOOL)status {
}

- (void)onUserBlockedOrUnBlocked:(NSString *)userId andBlockFlag:(BOOL)flag {
}

- (void)onUserDetailsUpdate:(ALUserDetail *)userDetail {
}

- (void)onUserMuteStatus:(ALUserDetail *)userDetail {
}

- (void)onChannelMute:(NSNumber *)channelKey {

}


@end
