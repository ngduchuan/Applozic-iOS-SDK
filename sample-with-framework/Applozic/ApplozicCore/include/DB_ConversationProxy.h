//
//  DB_ConversationProxy.h
//  Applozic
//
//  Created by devashish on 13/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

/// `DB_ConversationProxy` is DB class used for storing the conversation details in core data.
@interface DB_ConversationProxy : NSManagedObject

/// Set the conversation id.
@property (nonatomic, strong) NSNumber *iD;

/// Set the topicId.
@property (nonatomic, strong) NSString *topicId;

/// Set the groupId of conversation.
@property (nonatomic, strong) NSNumber *groupId;

/// Set the userId for the conversation for topic.
@property(nonatomic,strong) NSString *userId;

/// Set the created at time of conversation.
@property (nonatomic,retain) NSNumber *created;

/// It will have YES in case of conversation is closed else it will be NO.
@property(nonatomic,retain) NSNumber *closed;

/// Topic detail json string.
@property(nonatomic,strong) NSString *topicDetailJson;

@end
