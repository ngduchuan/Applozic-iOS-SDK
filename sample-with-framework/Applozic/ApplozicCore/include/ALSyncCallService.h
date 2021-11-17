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

@interface ALSyncCallService : NSObject

- (void)updateMessageDeliveryReport:(NSString *)messageKey withStatus:(int)status;

- (void)updateDeliveryStatusForContact:(NSString *)contactId withStatus:(int)status;

- (void)updateConnectedStatus:(ALUserDetail *)alUserDetail;

- (void)updateTableAtConversationDeleteForContact:(NSString *)contactID
                                   ConversationID:(NSString *)conversationID
                                       ChannelKey:(NSNumber *)channelKey;
- (void)syncMessageMetadata;

@end
