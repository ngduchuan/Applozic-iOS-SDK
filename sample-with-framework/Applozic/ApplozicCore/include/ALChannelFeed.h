//
//  ALChannelFeed.h
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALChannel.h"
#import "ALJson.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALChannelFeed` class is used for parsing the Channel JSON object.
@interface ALChannelFeed : ALJson

/// This will have array of `ALChannel` objects
@property (nonatomic) NSMutableArray <ALChannel *> * _Nullable channelFeedsList;

/// This will have in case of there are any conversation objects.
@property (nonatomic) NSMutableArray <ALChannel *> * _Nullable conversationProxyList;

@end
NS_ASSUME_NONNULL_END
