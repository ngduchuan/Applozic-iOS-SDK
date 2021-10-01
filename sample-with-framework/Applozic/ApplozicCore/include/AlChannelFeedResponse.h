//
//  AlChannelFeedResponse.h
//  Applozic
//
//  Created by Nitin on 20/10/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAPIResponse.h"
#import "ALChannel.h"

/// `AlChannelFeedResponse` class is used for channel information response parsing.
@interface AlChannelFeedResponse : ALAPIResponse

/// `ALChannel` will be set once the channel is fetched successfully.
@property (nonatomic, strong) ALChannel *alChannel;

/// In case of any error the errorResponse will be set can be accessed using `errorResponse`.
@property (nonatomic, strong) NSDictionary *errorResponse;

/// This method is used for passing JSON String from outside for parsing.
/// @param JSONString Pass the JSON String.
- (instancetype)initWithJSONString:(NSString *)JSONString;

@end
