//
//  ALGroupUser.h
//  Applozic
//
//  Created by Sunil on 14/02/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//
#import "ALJson.h"
#import <Foundation/Foundation.h>

/// `ALGroupUser` is used for creating channel members with the role during channel creation.
@interface ALGroupUser : ALJson

/// Set the member userId.
@property (nonatomic, strong) NSString *userId;

/// Set the member role these are roles for the member in the channel.
///
/// Roles are: USER = 0,
/// ADMIN = 1,
/// MODERATOR = 2,
/// MEMBER = 3
@property (nonatomic, strong) NSNumber *groupRole;

/// Passing the JSON Dictionary.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

@end
