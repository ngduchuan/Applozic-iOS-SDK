//
//  ALMessageList.h
//  ChatApp
//
//  Created by Devashish on 22/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALJson.h"
#import <Foundation/Foundation.h>

/// `ALMessageList` class is used for parsing the Message list or individual conversation JSON response.
@interface ALMessageList : ALJson

/// Array of `ALMessage` objects from an one-to-one or channel messges.
@property (nonatomic) NSMutableArray *messageList;

/// :nodoc:
@property (nonatomic) NSMutableArray *connectedUserList;

/// Array of `ALUserDetail` objects users who are currently had chat in one-to-one or channel conversation.
@property (nonatomic) NSMutableArray *userDetailsList;

/// Array of `ALConversationProxy` objects.
@property(nonatomic) NSMutableArray *conversationPxyList;

/// In case of one-to-one individual conversation the userId will be present otherwise, it will be nil.
@property(nonatomic) NSString *userId;

/// In case of Channel individual conversation the groupId or channelKey will be present otherwise, it will be nil.
@property(nonatomic) NSNumber *groupId;

/// Used for parsing the Message list or individual conversation JSON.
/// @param syncMessageResponse Pass the JSON response of list or individual conversation.
/// @param userId Set the userId for thread message.
/// @param groupId Set the channel key in case of channel conversation.
- (id)initWithJSONString:(NSString *)syncMessageResponse andWithUserId:(NSString *)userId andWithGroup:(NSNumber *)groupId;


@end
