//
//  ALChannel.h
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreData/NSManagedObject.h>
#import "ALJson.h"
#import "ALConversationProxy.h"

/// For internal use only.
static NSString *const AL_CHANNEL_DEFAULT_MUTE = @"MUTE";
/// For internal use only.
static NSString *const AL_CHANNEL_CONVERSATION_STATUS = @"CONVERSATION_STATUS";
/// For internal use only.
static NSString *const AL_CATEGORY = @"AL_CATEGORY";
/// :nodoc:
static NSString *const AL_CONTEXT_BASED_CHAT = @"AL_CONTEXT_BASED_CHAT";
/// :nodoc:
static NSString *const AL_CONVERSATION_ASSIGNEE = @"CONVERSATION_ASSIGNEE";

/// Channel types
typedef enum
{
    /// :nodoc:
    VIRTUAL = 0,
    /// Only admin can add member in the channel.
    PRIVATE = 1,
    /// Any one can join in the channel.
    PUBLIC = 2,
    /// :nodoc:
    SELLER = 3,
    /// :nodoc:
    SELF = 4,
    /// One way broadcast messages in channel.
    BROADCAST = 5,
    /// Used for user can chat without joining an channel.
    OPEN = 6,
    /// Group of two same as one-to-one chat.
    GROUP_OF_TWO = 7,
    /// Categorizing contacts can be created based on common interests or activities the members of the channel are used for showing in contacts section.
    CONTACT_GROUP = 9,
    /// :nodoc:
    SUPPORT_GROUP = 10,
    /// :nodoc:
    BROADCAST_ONE_BY_ONE = 106
} CHANNEL_TYPE;

/// :nodoc:
typedef enum {
    /// :nodoc:
    ALL_CONVERSATION = 0,
    /// :nodoc:
    ASSIGNED_CONVERSATION = 1,
    /// :nodoc:
    CLOSED_CONVERSATION = 3
} CONVERSATION_CATEGORY;

/**
 * A channel is a medium for multiple users to send and receive messages to and from each other. It facilitates a channel conversation.
 *
 * Channels are identified by their channel `key` which is auto generated or `clientChannelKey` which is your client channel key.
 *
 * Before a user can send messages to a channel, the channel needs to be created and the user needs to either join it or be added to it. Whether a user can join a channel or not depends on the channel `CHANNEL_TYPE`.
 *
 *   To create a channel and add users to it, refer to `-[ApplozicClient createChannelWithChannelInfo:withCompletion:]`.
 *
 *   To add a user to an existing channel (it allowed), refer to `-[ApplozicClient addMemberToChannelWithUserId:andChannelKey:orClientChannelKey:withCompletion:]`.
 *
 * To send a message to a channel refer to `-[ApplozicClient sendTextMessage:withCompletion:]`.
 */
@interface ALChannel : ALJson

/// Channel key is Identifier of Channel.
@property (nonatomic, strong) NSNumber *key;

/// Client channel key is Identifier of Channel.
///
/// If the client channel key is set during channel creation it will have its channel client key otherwise it will be a string of `key`.
@property (nonatomic, strong) NSString *clientChannelKey;

/// Channel name.
@property (nonatomic, strong) NSString *name;

/// Channel image URL.
@property (nonatomic, strong) NSString *channelImageURL;

/// Admin of the channel.
@property (nonatomic, strong) NSString *adminKey;

/// Used for identifying the type of channel the types are  `CHANNEL_TYPE`.
@property (nonatomic) short type;

/// Total number of users in channel.
@property (nonatomic, strong) NSNumber *userCount;

/// Total unread count in channel.
@property (nonatomic, strong) NSNumber *unreadCount;

/// For internal use only.
@property (nonatomic, strong) NSMutableArray *membersName;

/// For internal use only.
@property (nonatomic, strong) NSMutableArray *membersId;

/// :nodoc:
@property (nonatomic, strong) NSMutableArray *removeMembers;

/// :nodoc:
@property (nonatomic, strong) ALConversationProxy *conversationProxy DEPRECATED_ATTRIBUTE;

/// :nodoc:
@property (nonatomic, strong) NSNumber *parentKey;

/// :nodoc:
@property (nonatomic, strong) NSString *parentClientKey;

/// For internal use only.
@property (nonatomic, strong) NSMutableArray *groupUsers;

/// :nodoc:
@property (nonatomic, strong) NSMutableArray *childKeys;

/// To know when the channel is muted or unmuted it will have time in milliseconds otherwise nil.
@property (nonatomic, strong) NSNumber *notificationAfterTime;

/// If channel is deleted it will be > 0 otherwise nil or 0.
@property (nonatomic, strong) NSNumber *deletedAtTime;

/// Extra information in channel metadata.
@property (nonatomic, strong) NSMutableDictionary *metadata;

/// For internal use only.
///
/// This is used to categorize the channel based on the metadata value for `CONVERSATION_CATEGORY`
@property (nonatomic) short category;

/// :nodoc:
@property (nonatomic, copy) NSManagedObjectID *channelDBObjectId DEPRECATED_ATTRIBUTE;

/// For internal use only.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// For internal use only.
- (void)parseMessage:(id) messageJson;

/// :nodoc:
- (NSNumber *)getChannelMemberParentKey:(NSString *)userId;

/// Returns YES in case of notification are muted for current channel otherwise NO.
- (BOOL)isNotificationMuted;

/// :nodoc:
- (BOOL)isConversationClosed;

/// Returns YES in case of the channel is context-based chat otherwise NO.
- (BOOL)isContextBasedChat;

/// Returns YES in case of the channel is of type broadcast chat otherwise NO.
- (BOOL)isBroadcastGroup;

/// Returns YES in case of the channel is of type open otherwise NO.
- (BOOL)isOpenGroup;

/// Returns YES in case of the channel is of type group of two otherwise NO.
- (BOOL)isGroupOfTwo;

/// Returns YES in case of the channel is deleted otherwise NO.
- (BOOL)isDeleted;

/// Returns receiver member userId of group of two.
- (NSString*)getReceiverIdInGroupOfTwo;

/// For internal use only.
- (NSMutableDictionary *)getMetaDataDictionary:(NSString *)string;

/// Returns YES in case of channel is part of given category otherwise NO.
- (BOOL)isPartOfCategory:(NSString *)category;

/// For internal use only.
+ (CONVERSATION_CATEGORY)getConversationCategory:(NSDictionary *)metadata;

@end
