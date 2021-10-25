//
//  ApplozicClientTests.m
//  applozicdemoTests
//
//  Created by Mukesh Thawani on 23/08/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Applozic/Applozic.h>
#import <OCMock/OCMock.h>
#import "ALChatManager.h"

@interface ApplozicClientTests : XCTestCase

@end

@implementation ApplozicClientTests

ApplozicClient * client;
id mockService;
ALMessage *testMessage;
NSError *testError;

- (void)setUp {
    [super setUp];
    client = [[ApplozicClient alloc] initWithApplicationKey:APPLICATION_ID];
    mockService = OCMClassMock([ALMessageService class]);
    client.messageService = mockService;

    testMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
        alMessageBuilder.to = @"userId";
        alMessageBuilder.message = @"messageText";
    }];
    testError = [NSError errorWithDomain:@"Network Error" code:999 userInfo:nil];
}

- (void)test_whenTextMessageSentSuccessfully_thatErrorIsNil{

    OCMStub([mockService sendMessages:testMessage withCompletion:([OCMArg invokeBlockWithArgs:@"message",[OCMArg defaultValue], nil])]);
    [client sendTextMessage:testMessage withCompletion:^(ALMessage *message, NSError* error) {
        XCTAssert(error == nil);
        XCTAssert([message.message isEqualToString:@"messageText"]);
    }];
}

- (void)test_whenTextMessageSentUnsuccessful_thatErrorIsPresent{

    NSError *theError = [NSError errorWithDomain:@"Network Error" code:999 userInfo:nil];
    OCMStub([mockService sendMessages:testMessage withCompletion:([OCMArg invokeBlockWithArgs:@"message", theError, nil])]);
    [client sendTextMessage:testMessage withCompletion:^(ALMessage* message, NSError* error) {
        XCTAssert(error.code == 999);
        XCTAssert(message == nil);
    }];
}

- (void)test_whenTextMessagePassedIsNil_thatErrorIsPresent{
    [client sendTextMessage:nil withCompletion:^(ALMessage* message, NSError* error) {
        XCTAssert(error.code == MessageNotPresent);
    }];
}

- (void)test_whenLoadingInitialMessageListSuccessful_thatMessageListIsPresent{
    id mockDbService = OCMClassMock([ALMessageDBService class]);
    client.messageDbService = mockDbService;
    NSMutableArray *sampleMessageList = [[NSMutableArray alloc] initWithObjects:testMessage, nil];
    OCMStub([mockDbService getLatestMessages:NO withCompletionHandler:([OCMArg invokeBlockWithArgs:sampleMessageList, [OCMArg defaultValue], nil])]);
    [client getLatestMessages:NO withCompletionHandler:^(NSMutableArray* messageList, NSError* error) {
        XCTAssertNotNil(messageList);
        XCTAssertNil(error);
        XCTAssert(messageList.count == 1);
        if(messageList.count == 0) {
            return;
        }
        ALMessage *firstMessage = messageList.firstObject;
        XCTAssert(firstMessage.message == testMessage.message);
        XCTAssert(firstMessage.contactIds == testMessage.contactIds);
    }];
}

-(void)test_whenLoadingInitialMessageListUnsuccessful_thatErrorIsPresent {
    id mockDbService = OCMClassMock([ALMessageDBService class]);
    client.messageDbService = mockDbService;
    OCMStub([mockDbService getLatestMessages:NO withCompletionHandler:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], testError, nil])]);
    [client getLatestMessages:NO withCompletionHandler:^(NSMutableArray* messageList, NSError* error) {
        XCTAssertNotNil(error);
        XCTAssert(error.code == 999);
        XCTAssertNil(messageList);
    }];
}

-(void)test_whenLoadingMessagesForUserIdIsSuccessful_thatMessageListIsPresent {
    MessageListRequest *request = [[MessageListRequest alloc] init];
    request.userId = @"userid"; // pass userId
    NSMutableArray *sampleMessageList = [[NSMutableArray alloc] initWithObjects:testMessage, nil];
    OCMStub([mockService getMessageListForUser:request withCompletion:(sampleMessageList,[OCMArg defaultValue],[OCMArg defaultValue])]);
    [client getMessages: request withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
        XCTAssertNotNil(messageList);
        XCTAssertNil(error);
        XCTAssert(messageList.count == 1);
        if(messageList.count == 0) {
            return;
        }
        ALMessage *firstMessage = messageList.firstObject;
        XCTAssert(firstMessage.message == testMessage.message);
        XCTAssert(firstMessage.contactIds == testMessage.contactIds);
    }];
}

-(void)test_whenLoadingMessagesForUserIdIsUnsuccessful_thatErrorIsPresent {
    MessageListRequest *request = [[MessageListRequest alloc] init];
    request.userId = @"userid"; // pass userId
    OCMStub([mockService getMessageListForUser:request withCompletion:([OCMArg defaultValue],testError,[OCMArg defaultValue])]);
    [client getMessages: request withCompletionHandler:^(NSMutableArray *messageList, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssert(error.code == 999);
        XCTAssertNil(messageList);
    }];
}

-(void)test_whenMarkConversationIsSuccessful_thatErrorIsNotPresent {
    id userServiceMock = OCMClassMock([ALUserService class]);
    OCMStub([userServiceMock markConversationAsRead:@"userId" withCompletion:(@"Success", [OCMArg defaultValue], nil)]);
    [client markConversationReadForOnetoOne: @"userId" withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
    }];
}

-(void)test_whenMarkConversationIsUnsuccessful_thatErrorIsPresent {
    id userServiceMock = OCMClassMock([ALUserService class]);
    OCMStub([userServiceMock markConversationAsRead:@"userId" withCompletion:([OCMArg defaultValue], testError, nil)]);
    [client markConversationReadForOnetoOne: @"userId" withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

-(void)test_whenMarkConversationReadForGroupIsSuccessful_thatErrorIsNotPresent {
    id channelServiceMock = OCMClassMock([ALChannelService class]);
    NSNumber *groupId = [[NSNumber alloc] initWithInt:123];
    OCMStub([channelServiceMock markConversationAsRead:groupId withCompletion:(@"Success", [OCMArg defaultValue], nil)]);
    [client markConversationReadForGroup:groupId withCompletion:^(NSString *response, NSError *error){
        XCTAssertNil(error);
        XCTAssertNotNil(response);
    }];
}


-(void)test_whenMarkConversationReadForGroupIsUnsuccessful_thatErrorIsPresent {
    id channelServiceMock = OCMClassMock([ALChannelService class]);
    NSNumber *groupId = [[NSNumber alloc] initWithInt:123];
    OCMStub([channelServiceMock markConversationAsRead:groupId withCompletion:([OCMArg defaultValue], testError, nil)]);
    [client markConversationReadForGroup:groupId withCompletion:^(NSString *response, NSError *error){
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

@end
