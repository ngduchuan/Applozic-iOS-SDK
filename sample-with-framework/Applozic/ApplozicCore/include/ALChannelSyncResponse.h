//
//  ALChannelSyncResponse.h
//  Applozic
//
//  Created by devashish on 16/02/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAPIResponse.h"
#import "ALChannel.h"

/// `ALChannelSyncResponse` class is used for parasing the channel sync API response.
@interface ALChannelSyncResponse : ALAPIResponse

/// Array of channels that are fetched from sever it will be of type `ALChannel` class.
@property (nonatomic, strong) NSMutableArray *alChannelArray;

/// Will be used for init the JSON response string for parsing JSON data.
/// @param JSONString Pass the JSON response string.
- (instancetype)initWithJSONString:(NSString *)JSONString;

@end
