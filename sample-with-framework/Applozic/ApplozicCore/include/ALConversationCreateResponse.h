//
//  ALConversationCreateResponse.h
//  Applozic
//
//  Created by Divjyot Singh on 04/03/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import "ALConversationProxy.h"
#import <Foundation/Foundation.h>

/// `ALConversationCreateResponse` class is used for context based conversation create response parsing.
@interface ALConversationCreateResponse : ALAPIResponse

/// This will be set from `initWithJSONString` method.
@property (nonatomic, strong) ALConversationProxy *alConversationProxy;

/// This method is used for parsing the conversation create JSON string
/// @param JSONString Pass the JSON response string.
- (instancetype)initWithJSONString:(NSString *)JSONString;
@end
