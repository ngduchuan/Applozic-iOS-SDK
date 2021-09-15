//
//  ALChannelCreateResponse.h
//  Applozic
//
//  Created by devashish on 12/02/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAPIResponse.h"
#import "ALChannel.h"

/// `ALChannelCreateResponse` class is used for parsing the JSON response of Channel create.
@interface ALChannelCreateResponse : ALAPIResponse

/// This channel is set from `initWithJSONString` method can be accessed once the JSON is passed.
@property (nonatomic, strong) ALChannel *alChannel;

/// This method is used for parsing the Channel create response.
/// @param JSONString Pass the JSON  response string.
- (instancetype)initWithJSONString:(NSString *)JSONString;

@end
