//
//  ALConversationClientService.h
//  Applozic
//
//  Created by Divjyot Singh on 04/03/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALConstant.h"
#import "ALConversationCreateResponse.h"
#import "ALConversationProxy.h"
#import "ALResponseHandler.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALConversationClientService` is used for conversation client methods like create, fetch conversation.
@interface ALConversationClientService : NSObject

/// Instance method of `ALResponseHandler` object.
@property (nonatomic, strong) ALResponseHandler *responseHandler;

/// This method is used for creating a context based chat conversation on server.
/// @param conversationProxy Pass the `ALConversationProxy` object.
/// @param completion If any error then NSError will not be nil and In `ALConversationCreateResponse` if status is sucess is then conversation is created successfully otherwise there wil be error in status.
- (void)createConversation:(ALConversationProxy *)conversationProxy
            withCompletion:(void(^)(NSError * _Nullable error, ALConversationCreateResponse * _Nullable response))completion;

/// This method is used for fetching topic details from server.
/// @param conversationProxyID Pass the conversationId.
/// @param completion If any error then NSError will not be nil and In `ALConversationCreateResponse` if status is sucess is then conversation is created successfully otherwise there wil be error in status.
- (void)fetchTopicDetails:(NSNumber *)conversationProxyID andCompletion:(void (^)(NSError * _Nullable error , ALAPIResponse * _Nullable response))completion;
@end

NS_ASSUME_NONNULL_END
