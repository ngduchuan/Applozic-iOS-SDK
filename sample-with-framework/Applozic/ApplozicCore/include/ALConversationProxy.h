//
//  ALConversationProxy.h
//  Applozic
//
//  Created by devashish on 07/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"
#import "ALTopicDetail.h"
#import "DB_ConversationProxy.h"

/// `ALConversationProxy` class is used parsing JSON response of context based chat.
@interface ALConversationProxy : ALJson

/// Sets the conversation id.
@property (nonatomic, strong) NSNumber *Id;

/// Set the topicId.
@property (nonatomic, strong) NSString *topicId;

/// Topic detail json string.
@property (nonatomic, strong) NSString *topicDetailJson;

/// Set the groupId of conversation.
@property (nonatomic, strong) NSNumber *groupId;

/// Set the userId for the conversation for topic.
@property (nonatomic, strong) NSString *userId;

/// <#Description#>
@property (nonatomic, strong) NSArray *supportIds;

/// <#Description#>
@property (nonatomic, strong) NSMutableArray *fallBackTemplatesListArray;

/// <#Description#>
@property (nonatomic, strong) NSMutableDictionary *fallBackTemplateForSENDER;

/// <#Description#>
@property (nonatomic, strong) NSMutableDictionary *fallBackTemplateForRECEIVER;

/// <#Description#>
@property (nonatomic) BOOL created;

/// <#Description#>
@property (nonatomic) BOOL closed;

/// The method is used for parsing JSON.
/// @param messageJson Pass the JSON for parsing.
- (void)parseMessage:(id)messageJson;

/// This method is used for parsing the context based conversation.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// Description
- (ALTopicDetail *)getTopicDetail;

/// <#Description#>
/// @param alConversationProxy <#alConversationProxy description#>
+ (NSMutableDictionary *)getDictionaryForCreate:(ALConversationProxy *)alConversationProxy;

/// <#Description#>
/// @param senderFormatString <#senderFormatString description#>
- (void)setSenderSMSFormat:(NSString *)senderFormatString;

/// <#Description#>
/// @param recieverFormatString <#recieverFormatString description#>
- (void)setReceiverSMSFormat:(NSString *)recieverFormatString;

@end
