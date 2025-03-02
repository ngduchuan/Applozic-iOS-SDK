//
//  ALMessageList.h
//  ChatApp
//
//  Created by Devashish on 22/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALJson.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALMessageList` class is used for parsing the Message list or individual conversation JSON response.
@interface ALMessageList : ALJson

/// Array of `ALMessage` objects from an one-to-one or channel messges.
@property (nonatomic) NSMutableArray * _Nullable messageList;

/// :nodoc:
@property (nonatomic) NSMutableArray * _Nullable connectedUserList;

/// Array of `ALUserDetail` objects users who are currently had chat in one-to-one or channel conversation.
@property (nonatomic) NSMutableArray * _Nullable userDetailsList;

/// Array of `ALConversationProxy` objects.
@property(nonatomic) NSMutableArray * _Nullable conversationPxyList;

/// In case of one-to-one individual conversation the userId will be present otherwise, it will be nil.
@property(nonatomic) NSString * _Nullable userId;

/// In case of Channel individual conversation the groupId or channelKey will be present otherwise, it will be nil.
@property(nonatomic) NSNumber * _Nullable groupId;

/// Used for parsing the Message list or individual conversation JSON.
/// @param syncMessageResponse Pass the JSON response of list or individual conversation.
/// @param userId Set the userId for thread message.
/// @param groupId Set the channel key in case of channel conversation.
- (id)initWithJSONString:(NSString *)syncMessageResponse andWithUserId:(NSString * _Nullable)userId andWithGroup:(NSNumber * _Nullable)groupId;


@end
NS_ASSUME_NONNULL_END
