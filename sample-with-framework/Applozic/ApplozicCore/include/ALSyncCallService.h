//
//  ALSyncCallService.h
//  Applozic
//
//  Created by Applozic Inc on 12/14/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALMessage.h"
#import "ALRealTimeUpdate.h"
#import "ALUserDetail.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALSyncCallService : NSObject

- (void)updateMessageDeliveryReport:(NSString *)messageKey withStatus:(int)status;

- (void)updateDeliveryStatusForContact:(NSString *)contactId withStatus:(int)status;

- (void)updateConnectedStatus:(ALUserDetail *)alUserDetail;

- (void)updateTableAtConversationDeleteForContact:(NSString * _Nullable)contactID
                                   ConversationID:(NSString * _Nullable)conversationID
                                       ChannelKey:(NSNumber * _Nullable)channelKey;
- (void)syncMessageMetadata;

@end

NS_ASSUME_NONNULL_END
