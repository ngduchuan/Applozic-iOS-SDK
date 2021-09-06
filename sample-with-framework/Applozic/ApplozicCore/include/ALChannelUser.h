//
//  ALChannelUser.h
//  Applozic
//
//  Created by Adarsh Kumar Mishra on 12/8/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALJson.h"

/// `ALChannelUser` this class is used for creating channel members with role during channel creation.
@interface ALChannelUser : ALJson

/// Set the member role this are roles for member in channel.
///
/// Roles are: USER = 0,
/// ADMIN = 1,
/// MODERATOR = 2,
/// MEMBER = 3
@property (nonatomic, strong) NSNumber *role;

/// Set the member userId.
@property (nonatomic, strong) NSString *userId;

/// The partent group key is the parent channelKey.
@property (nonatomic, strong) NSNumber *parentGroupKey;

/// This method is used passing the JSON Dictionary.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// This method used parsing JSON string.
/// @param messageJson Pass the JSON Dictionary.
- (void)parseMessage:(id)messageJson;

@end
