//
//  ALMessageInfo.h
//  Applozic
//
//  Created by devashish on 17/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALJson.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// `ALMessageInfo` class is used for parsing the Message information JSON data and mapping it.
@interface ALMessageInfo : ALJson

/// UserId of the User.
@property (nonatomic, strong) NSString * _Nullable userId;

/// Status of message.
///
/// The status are : SENT = 3,
/// DELIVERED = 4,
/// DELIVERED_AND_READ = 5
@property (nonatomic) short status;

/// This method is used for parsing the JSON Dictionary of Message information.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

@end

NS_ASSUME_NONNULL_END
