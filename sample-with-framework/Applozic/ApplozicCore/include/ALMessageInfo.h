//
//  ALMessageInfo.h
//  Applozic
//
//  Created by devashish on 17/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"

/// `ALMessageInfo` class is used for parsing the Message information JSON data and mapping it
@interface ALMessageInfo : ALJson

/// UserId of the User.
@property (nonatomic, strong) NSString *userId;

/// Status of message.
///
/// The status are : SENT = 3,
/// DELIVERED = 4,
/// DELIVERED_AND_READ = 5
@property (nonatomic) short status;

/// This method is used for parsing the JSON Dictionary of Message information.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// This method is used for parsing the JSON Dictionary of Message information.
/// @param messageJson Pass JSON data.
- (void)parseMessage:(id)messageJson;

@end
