//
//  ALConversationProxy.h
//  Applozic
//
//  Created by devashish on 07/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALJson.h"
#import "ALTopicDetail.h"
#import "DB_ConversationProxy.h"
#import <Foundation/Foundation.h>

/// `ALConversationProxy` class is used parsing JSON response of context based chat.
@interface ALConversationProxy : ALJson

/// Sets the conversation id.
@property (nonatomic, strong) NSNumber *Id;

/// Sets the topicId.
@property (nonatomic, strong) NSString *topicId;

/// Topic detail json string.
@property (nonatomic, strong) NSString *topicDetailJson;

/// Sets the groupId of conversation.
@property (nonatomic, strong) NSNumber *groupId;

/// Sets the userId for the conversation for topic.
@property (nonatomic, strong) NSString *userId;

/// :nodoc:
@property (nonatomic, strong) NSArray *supportIds;

/// :nodoc:
@property (nonatomic, strong) NSMutableArray *fallBackTemplatesListArray;

/// :nodoc:
@property (nonatomic, strong) NSMutableDictionary *fallBackTemplateForSENDER;

/// :nodoc:
@property (nonatomic, strong) NSMutableDictionary *fallBackTemplateForRECEIVER;

/// :nodoc:
@property (nonatomic) BOOL created;

/// :nodoc:
@property (nonatomic) BOOL closed;

/// This method is used for parsing the context based conversation.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// Returns the topic detail.
- (ALTopicDetail *)getTopicDetail;

/// Gets the dictionary from `ALConversationProxy`.
/// @param alConversationProxy Pass the `ALConversationProxy` object.
+ (NSMutableDictionary *)getDictionaryForCreate:(ALConversationProxy *)alConversationProxy;

/// :nodoc:
- (void)setSenderSMSFormat:(NSString *)senderFormatString;

/// :nodoc:
- (void)setReceiverSMSFormat:(NSString *)recieverFormatString;

@end
