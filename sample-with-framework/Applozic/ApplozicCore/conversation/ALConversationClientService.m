//
//  ALConversationClientService.m
//  Applozic
//
//  Created by Divjyot Singh on 04/03/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//
#import "ALConversationClientService.h"
#import "ALConversationDBService.h"
#import "ALLogger.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALVerification.h"

static NSString *const CREATE_CONVERSATION_URL = @"/rest/ws/conversation/id";
static NSString *const FETCH_CONVERSATION_DETAILS = @"/rest/ws/conversation/topicId";

@implementation ALConversationClientService

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupServices];
    }
    return self;
}

- (void)setupServices {
    self.responseHandler = [[ALResponseHandler alloc] init];
}

#pragma mark - Create conversation

- (void)createConversation:(ALConversationProxy *)conversationProxy
            withCompletion:(void(^)(NSError *error, ALConversationCreateResponse *response))completion {
    
    NSString *conversationURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, CREATE_CONVERSATION_URL];
    
    NSDictionary *dictionaryToSend = [NSDictionary dictionaryWithDictionary:[ALConversationProxy getDictionaryForCreate:conversationProxy]];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:dictionaryToSend options:0 error:&error];
    NSString *conversationParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    NSMutableURLRequest *conversationRequest = [ALRequestHandler createPOSTRequestWithUrlString:conversationURLString paramString:conversationParamString];
    [self.responseHandler authenticateAndProcessRequest:conversationRequest andTag:@"CREATE_CONVERSATION" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        ALConversationCreateResponse *response = nil;
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN CREATE_CONVERSATION %@", error);
        } else {

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to create conversation the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to create conversation the response is nil." forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            ALSLog(ALLoggerSeverityInfo, @"SEVER RESPONSE FROM JSON CREATE_CONVERSATION : %@", jsonResponse);
            response = [[ALConversationCreateResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];
}

- (void)fetchTopicDetails:(NSNumber *)conversationProxyID
            andCompletion:(void (^)(NSError *, ALAPIResponse *))completion {
    
    NSString *conversationDetailURLString = [NSString stringWithFormat:@"%@%@",KBASE_URL, FETCH_CONVERSATION_DETAILS];
    NSString *conversationDetailParamString = [NSString stringWithFormat:@"id=%@",conversationProxyID];
    
    NSMutableURLRequest *conversationDetailRequest =  [ALRequestHandler createGETRequestWithUrlString:conversationDetailURLString paramString:conversationDetailParamString];
    
    [self.responseHandler authenticateAndProcessRequest:conversationDetailRequest andTag:@"FETCH_TOPIC_DETAILS" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN FETCH_TOPIC_DETAILS SERVER CALL REQUEST %@", error);
        } else {

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to fetch the topic details the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to fetch the topic details the response is nil." forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];
}

@end
