//
//  ALSyncCallService.m
//  Applozic
//
//  Created by Applozic Inc on 12/14/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALChannelService.h"
#import "ALContactDBService.h"
#import "ALLogger.h"
#import "ALMessageDBService.h"
#import "ALMessageService.h"
#import "ALSyncCallService.h"

@implementation ALSyncCallService


- (void)updateMessageDeliveryReport:(NSString *)messageKey withStatus:(int)status {
    ALMessageDBService *alMessageDBService = [[ALMessageDBService alloc] init];
    [alMessageDBService updateMessageDeliveryReport:messageKey withStatus:status];
    ALSLog(ALLoggerSeverityInfo, @"delivery report for %@", messageKey);
    //Todo: update ui
}

- (void)updateDeliveryStatusForContact:(NSString *)contactId withStatus:(int)status {
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    [messageDBService updateDeliveryReportForContact:contactId withStatus:status];
    //Todo: update ui
}

- (void)updateConnectedStatus:(ALUserDetail *)userDetail {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userUpdate" object:userDetail];
    ALContactDBService *contactDBService = [[ALContactDBService alloc] init];
    [contactDBService updateLastSeenDBUpdate:userDetail];
}

- (void)updateTableAtConversationDeleteForContact:(NSString *)contactID
                                   ConversationID:(NSString *)conversationID
                                       ChannelKey:(NSNumber *)channelKey {
    
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    [messageDBService deleteAllMessagesByContact:contactID orChannelKey:channelKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CONVERSATION_DELETION"
                                                        object:(contactID ? contactID :channelKey)];
    
}

- (void)syncMessageMetadata {
    [ALMessageService syncMessageMetaData:[ALUserDefaultsHandler getDeviceKeyString] withCompletion:^(NSMutableArray *message, NSError *error) {
        ALSLog(ALLoggerSeverityInfo, @"Successfully updated message metadata");
    }];
}

@end