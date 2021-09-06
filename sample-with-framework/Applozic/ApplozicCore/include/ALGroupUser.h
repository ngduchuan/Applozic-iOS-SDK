//
//  ALGroupUser.h
//  Applozic
//
//  Created by Sunil on 14/02/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//
#import "ALJson.h"
#import <Foundation/Foundation.h>


/// `ALGroupUser` this class is used for creating channel members with role during channel creation.
@interface ALGroupUser : ALJson

/// Set the member userId.
@property (nonatomic, strong) NSString *userId;

/// Set the member role this are roles for member in channel.
///
/// Roles are:  USER = 0,
/// ADMIN = 1,
/// MODERATOR = 2,
/// MEMBER = 3
@property (nonatomic, strong) NSNumber *groupRole;

/// This method is used passing the JSON Dictionary.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

@end
