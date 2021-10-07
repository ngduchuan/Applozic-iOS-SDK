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

/// `ALChannelFeed` class is used for parsing the Channel JSON object.
@interface ALChannelFeed : ALJson

/// This will have array of `ALChannel` objects
@property (nonatomic) NSMutableArray <ALChannel *> *channelFeedsList;

/// This will have in case of there are any conversation objects.
@property (nonatomic) NSMutableArray <ALChannel *> *conversationProxyList;

@end
