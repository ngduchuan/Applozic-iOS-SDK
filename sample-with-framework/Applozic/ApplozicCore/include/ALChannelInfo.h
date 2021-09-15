//
//  ALChannelInfo.h
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"

/// `ALChannelInfo` this class is used creating Info object for creating Channel.
@interface ALChannelInfo : ALJson

/// Set the channel or group name.
@property (nonatomic, strong) NSString *groupName;

/// Set your own client group id.
@property (nonatomic, strong) NSString *clientGroupId;

/// Set the the members userId that you want to add in the channel or group.
@property (nonatomic, strong) NSMutableArray *groupMemberList;

/// Set the Image URL for channel or group.
@property (nonatomic, strong) NSString *imageUrl;

/// Set the admin userId of the channel or group.
@property (nonatomic, strong) NSString *admin;

/// Set the parent client groupId.
@property (nonatomic, strong) NSString *parentClientGroupId;

/// Set the parent client channel key.
@property (nonatomic, strong) NSNumber *parentKey;

/// Set the type of the channel.
///
/// This are types of channel or group:
/// PRIVATE = 1,
/// PUBLIC = 2,
/// SELLER = 3,
/// BROADCAST = 5,
/// OPEN = 6,
/// GROUP_OF_TWO = 7,
/// CONTACT_GROUP = 9,
/// SUPPORT_GROUP = 10,
/// BROADCAST_ONE_BY_ONE = 106.
@property(nonatomic) short type;

/// Set the channel meta data.
@property (nonatomic, strong) NSMutableDictionary *metadata;

/// Set the array of the channel users of type `ALGroupUser`.
@property (nonatomic, strong) NSMutableArray *groupRoleUsers;

@end
