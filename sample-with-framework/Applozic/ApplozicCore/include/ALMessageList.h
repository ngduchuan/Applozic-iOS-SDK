//
//  ALMessageList.h
//  ChatApp
//
//  Created by Devashish on 22/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"

/// `ALMessageList` class is used for parsing the Message list or Message thread JSON response.
@interface ALMessageList : ALJson

/// The array of `ALMessage` objects.
@property (nonatomic) NSMutableArray *messageList;

/// :nodoc:
@property (nonatomic) NSMutableArray *connectedUserList;

/// The array of `ALUserDetail` objects.
@property (nonatomic) NSMutableArray *userDetailsList;

/// The array of `ALConversationProxy` objects.
@property(nonatomic) NSMutableArray *conversationPxyList;

/// In case of Message thread the userId will be present else it will be nil
@property(nonatomic) NSString *userId;

/// In case of Message thread the groupId will be present else it will be nil
@property(nonatomic) NSNumber *groupId;


/// This method is used for parsing the Message list or Message thread JSON.
/// @param syncMessageResponse Pass the JSON response of list or thread message
/// @param userId Set the userId for thread message.
/// @param groupId Set the groupId in case of channel or group conversation
- (id)initWithJSONString:(NSString *)syncMessageResponse andWithUserId:(NSString *)userId andWithGroup:(NSNumber *)groupId;


@end
