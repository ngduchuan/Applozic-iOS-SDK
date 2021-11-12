//
//  ALChannelFeedResponse.h
//  Applozic
//
//  Created by Nitin on 20/10/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import "ALChannel.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALChannelFeedResponse` class is used for channel information response parsing.
@interface ALChannelFeedResponse : ALAPIResponse

/// `ALChannel` will be set once the channel is fetched successfully.
@property (nonatomic, strong) ALChannel * _Nullable alChannel;

/// In case of any error the errorResponse will be set can be accessed using `errorResponse`.
@property (nonatomic, strong) NSDictionary * _Nullable errorResponse;

/// Used for parsing a JSON string.
/// @param JSONString Pass the JSON String.
- (instancetype)initWithJSONString:(NSString *)JSONString;

@end

NS_ASSUME_NONNULL_END
