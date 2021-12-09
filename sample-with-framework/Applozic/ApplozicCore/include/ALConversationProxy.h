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

NS_ASSUME_NONNULL_BEGIN
/// `ALConversationProxy` class is used parsing JSON response of context based chat.
@interface ALConversationProxy : ALJson

/// Sets the conversation id.
@property (nonatomic, strong) NSNumber * _Nullable Id;

/// Sets the topicId.
@property (nonatomic, strong) NSString * _Nullable topicId;

/// Topic detail json string.
@property (nonatomic, strong) NSString * _Nullable topicDetailJson;

/// Sets the groupId of conversation.
@property (nonatomic, strong) NSNumber * _Nullable groupId;

/// Sets the userId for the conversation for topic.
@property (nonatomic, strong) NSString * _Nullable userId;

/// :nodoc:
@property (nonatomic, strong) NSArray * _Nullable supportIds;

/// :nodoc:
@property (nonatomic, strong) NSMutableArray * _Nullable fallBackTemplatesListArray;

/// :nodoc:
@property (nonatomic, strong) NSMutableDictionary * _Nullable fallBackTemplateForSENDER;

/// :nodoc:
@property (nonatomic, strong) NSMutableDictionary * _Nullable fallBackTemplateForRECEIVER;

/// :nodoc:
@property (nonatomic) BOOL created;

/// :nodoc:
@property (nonatomic) BOOL closed;

/// This method is used for parsing the context based conversation.
/// @param messageDictonary Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)messageDictonary;

/// Returns the topic detail.
- (ALTopicDetail * _Nullable)getTopicDetail;

/// Gets the dictionary from `ALConversationProxy`.
/// @param conversationProxy Pass the `ALConversationProxy` object.
+ (NSMutableDictionary *)getDictionaryForCreate:(ALConversationProxy *)conversationProxy;

/// :nodoc:
- (void)setSenderSMSFormat:(NSString *)senderFormatString;

/// :nodoc:
- (void)setReceiverSMSFormat:(NSString *)recieverFormatString;

@end

NS_ASSUME_NONNULL_END
