//
//  ALMessageServiceTest.m
//  applozicdemoTests
//
//  Created by Sunil on 11/06/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Applozic/Applozic.h>

@interface ALMessageServiceTest : XCTestCase

@end

@implementation ALMessageServiceTest {
    id mockMessageService;
    id mockMessageClientService;
    id mockDbService;
    id mockResponseHandler;
    NSError *networkError;
    ALMessage *testMessage;
    ALMessageService *messageService;
    ALMessageDBService *messageDBService;
}


- (void)setUp {
    [super setUp];

    messageService = [[ALMessageService alloc] init];
    messageDBService = [[ALMessageDBService alloc] init];
    mockResponseHandler = OCMClassMock([ALResponseHandler class]);

    mockMessageService = OCMClassMock([ALMessageService class]);
    mockMessageClientService  = OCMClassMock([ALMessageClientService class]);
    [mockMessageClientService setResponseHandler:mockResponseHandler];
    messageService.messageClientService = mockMessageClientService;
    mockDbService = OCMClassMock([ALMessageDBService class]);

    messageDBService.messageService = mockMessageService;
    testMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
        alMessageBuilder.to = @"userId";
        alMessageBuilder.message = @"messageText";
    }];

    networkError = [NSError errorWithDomain:@"Network Error" code:999 userInfo:nil];
  
}


- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [mockMessageService stopMocking];
    [mockMessageClientService stopMocking];
    [mockDbService stopMocking];
    [mockResponseHandler stopMocking];
    [super tearDown];
}

// MARK: - Send Message

- (void)test_whenTextMessageSentSuccessfully_thatErrorIsNil {

    OCMStub([mockMessageService sendMessages:testMessage withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue] ,[OCMArg defaultValue], nil])]);

    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];

    [jsonDictionary setValue:@1623664309876 forKey:@"generatedAt"];

    NSDictionary *responseDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"1623664309847",@"createdAt",@"5-aca8f645-dd68-4f79-bcd7-c52701322026-1623663155118",@"messageKey", nil];

    [jsonDictionary setObject:responseDictionary forKey:@"response"];
    [jsonDictionary setValue:@"success" forKey:@"status"];

    OCMStub([mockMessageClientService sendMessage:[testMessage dictionary] WithCompletionHandler:([OCMArg invokeBlockWithArgs:jsonDictionary,[OCMArg defaultValue], nil])]);
    [messageService sendMessages:testMessage withCompletion:^(NSString *message, NSError *error) {
        XCTAssert(error == nil);
        XCTAssert(message == nil);
    }];
}

- (void)test_whenTextMessageSentUnsuccessful_thatErrorIsPresent {
    OCMStub([mockMessageClientService sendMessage:[testMessage dictionary] WithCompletionHandler:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue] , networkError, nil])]);

    [messageService sendMessages:testMessage withCompletion:^(NSString *message, NSError *error) {
        XCTAssert(error.code == 999);
        XCTAssert(message == nil);
    }];
}

- (void)test_whenTextMessagePassedIsNil_thatErrorIsPresent {
    [messageService sendMessages:nil withCompletion:^(NSString *message, NSError *error) {
        XCTAssert(error.code == MessageNotPresent);
        XCTAssert(message == nil);
    }];
}

// MARK: - Message list

- (void)test_whenLoadingInitialMessageListSuccessful_thatMessageListIsPresent {
    NSMutableArray *sampleMessageList = [[NSMutableArray alloc] initWithObjects:testMessage, nil];
    OCMStub([mockDbService fetchAndRefreshFromServerWithCompletion:([OCMArg invokeBlockWithArgs:sampleMessageList, [OCMArg defaultValue], nil])]);

    OCMStub([mockDbService getLatestMessagesWithCompletion:([OCMArg invokeBlockWithArgs:sampleMessageList, [OCMArg defaultValue], nil])]);

    OCMStub([mockMessageService getMessagesListGroupByContactswithCompletionService:([OCMArg invokeBlockWithArgs:sampleMessageList, [OCMArg defaultValue], nil])]);

    [messageDBService getLatestMessages:NO withCompletionHandler:^(NSMutableArray *messageList, NSError* error) {
        XCTAssertNotNil(messageList);
        XCTAssertNil(error);
        if (messageList.count == 0) {
            return;
        }
        XCTAssert(messageList.count > 0);
    }];
}

- (void)test_whenLoadingInitialMessageListUnsuccessful_thatErrorIsPresent {

    OCMStub([mockDbService fetchAndRefreshFromServerWithCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], networkError, nil])]);

    OCMStub([mockDbService getLatestMessagesWithCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], networkError, nil])]);

    OCMStub([mockMessageService getMessagesListGroupByContactswithCompletionService:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], networkError, nil])]);

    [messageDBService getLatestMessages:NO withCompletionHandler:^(NSMutableArray *messageList, NSError* error) {
        if (messageList.count == 0) {
            XCTAssertNotNil(error);
            return;
        }
        XCTAssertNotNil(messageList);
    }];
}

// MARK: - Messages or conversation of user or group chat

- (void)test_whenLoadingMessagesForUserIsSuccessful_thatMessageListIsPresent {
    MessageListRequest *request = [[MessageListRequest alloc] init];
    request.userId = @"userid"; // pass userId
    NSMutableArray *sampleMessageList = [[NSMutableArray alloc] initWithObjects:testMessage, nil];
    OCMStub([mockMessageClientService getMessageListForUser:request withOpenGroup:NO
                                             withCompletion:([OCMArg invokeBlockWithArgs:sampleMessageList,
                                                              [OCMArg defaultValue],
                                                              [OCMArg defaultValue], nil])]);

    [messageService getMessageListForUser:request withCompletion:^(NSMutableArray *messageList, NSError *error, NSMutableArray *userDetailArray) {

        XCTAssertNotNil(messageList);
        XCTAssertNil(error);
        XCTAssert(messageList.count == 1);
    }];
}

- (void)test_whenLoadingMessagesForUserIsUnsuccessful_thatErrorIsPresent {
    MessageListRequest *request = [[MessageListRequest alloc] init];
    request.userId = @"userid"; // pass userId

    OCMStub([mockMessageClientService getMessageListForUser:request withOpenGroup:NO
                                             withCompletion:([OCMArg invokeBlockWithArgs :[OCMArg defaultValue], networkError,[OCMArg defaultValue], nil])]);

    [messageService getMessageListForUser:request withCompletion:^(NSMutableArray *messageList, NSError *error, NSMutableArray *userDetailArray) {
        XCTAssertNotNil(error);
        XCTAssert(error.code == 999);
        XCTAssertNil(messageList);
    }];
}

- (void)test_whenLoadingMessagesRequestIsNil {
    MessageListRequest *request = nil;

    OCMStub([mockMessageClientService getMessageListForUser:request withOpenGroup:NO
                                             withCompletion:([OCMArg invokeBlockWithArgs :[OCMArg defaultValue], networkError,[OCMArg defaultValue], nil])]);

    [messageService getMessageListForUser:request withCompletion:^(NSMutableArray *messageList, NSError *error, NSMutableArray *userDetailArray) {
        XCTAssertNotNil(error);
        XCTAssertNil(messageList);
    }];
}

- (void)test_whenLoadingMessagesForChannelIsSuccessful_thatMessageListIsPresent {
    MessageListRequest *request = [[MessageListRequest alloc] init];
    request.channelKey = @1234; // pass channelkey

    ALMessage *message = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
        alMessageBuilder.groupId = @1234;
        alMessageBuilder.message = @"messageText";
    }];

    NSMutableArray *sampleMessageList = [[NSMutableArray alloc] initWithObjects:message, nil];
    OCMStub([mockMessageClientService getMessageListForUser:request withOpenGroup:NO
                                             withCompletion:([OCMArg invokeBlockWithArgs:sampleMessageList,
                                                              [OCMArg defaultValue],
                                                              [OCMArg defaultValue], nil])]);

    [messageService getMessageListForUser:request withCompletion:^(NSMutableArray *messageList, NSError *error, NSMutableArray *userDetailArray) {

        XCTAssertNotNil(messageList);
        XCTAssertNil(error);
        XCTAssert(messageList.count == 1);
    }];
}

// MARK: - Message delete for all

- (void)test_deleteMessageForAllIsUnsuccessful_thatErrorIsPresent {

    OCMStub([mockMessageClientService deleteMessageForAllWithKey:@"messagekey1"
                                                  withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                                   networkError,
                                                                   nil])]);

    NSString *theUrlString = [NSString stringWithFormat:@"%@/rest/ws/message/v2/delete",KBASE_URL];
    NSString *theParamString = [NSString stringWithFormat:@"key=%@&deleteForAll=true", @"messagekey1"];

    NSMutableURLRequest *theRequest = [ALRequestHandler createGETRequestWithUrlString:theUrlString paramString:theParamString];

    OCMStub([mockResponseHandler authenticateAndProcessRequest:theRequest
                                                        andTag:@"DELETE_MESSAGE_FOR_ALL"
                                         WithCompletionHandler:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                                 networkError,
                                                                 nil])]);

    [messageService deleteMessageForAllWithKey:@"messagekey1"
                                withCompletion:^(ALAPIResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssert(error.code == 999);
        XCTAssertNil(response);
    }];
}

- (void)test_deleteMessageForAllMessageKeyIsNil {

    [messageService deleteMessageForAllWithKey:nil
                                withCompletion:^(ALAPIResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

- (void)test_deleteMessageForAllIsSuccessful {

    ALAPIResponse *mockApiResponse = [[ALAPIResponse alloc] init];
    mockApiResponse.generatedAt = @1623926734139;
    mockApiResponse.response = @"success";
    mockApiResponse.status = @"success";

    OCMStub([mockMessageService deleteMessageForAllWithKey:@"messagekey1"
                                            withCompletion:([OCMArg invokeBlockWithArgs:mockApiResponse,
                                                             [OCMArg defaultValue],
                                                             nil])]);

    OCMStub([mockMessageClientService deleteMessageForAllWithKey:@"messagekey1"
                                                  withCompletion:([OCMArg invokeBlockWithArgs:mockApiResponse,
                                                                   [OCMArg defaultValue],
                                                                   nil])]);

    [messageService deleteMessageForAllWithKey:@"messagekey1"
                                withCompletion:^(ALAPIResponse *response, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
        XCTAssertEqual(mockApiResponse.generatedAt, response.generatedAt);
    }];
}

// MARK: - Message Thread for user or channel


- (void)test_deleteMessageThreadWhereParametersAreNil {

    [messageService deleteMessageThread:nil
                           orChannelKey:nil
                         withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(status);
    }];
}

- (void)test_deleteMessageThreadForUserIsUnsuccessful_thatErrorIsPresent {

    OCMStub([mockMessageClientService deleteMessageThread:@"userId"
                                             orChannelKey:nil
                                           withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                            networkError,
                                                            nil])]);

    [messageService deleteMessageThread:@"userId"
                           orChannelKey:nil
                         withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssert(error.code == 999);
        XCTAssertNil(status);
    }];
}

- (void)test_deleteMessageThreadForUserIsSuccessful {

    OCMStub([mockMessageClientService deleteMessageThread:@"userId"
                                             orChannelKey:nil
                                           withCompletion:([OCMArg invokeBlockWithArgs:@"success",
                                                            [OCMArg defaultValue],
                                                            nil])]);

    [messageService deleteMessageThread:@"userId"
                           orChannelKey:nil
                         withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(status);
    }];
}


- (void)test_deleteMessageThreadForChannelIsSuccessful {

    OCMStub([mockMessageClientService deleteMessageThread:nil orChannelKey:@1234 withCompletion:([OCMArg invokeBlockWithArgs:@"success" ,[OCMArg defaultValue], nil])]);

    [messageService deleteMessageThread:nil orChannelKey:@1234  withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(status);
    }];
}


// MARK: - Message delete by message key

- (void)test_deleteMessageForMessageKeyIsSuccessful {

    NSString *messageKey = @"messageKey1";

    OCMStub([mockMessageClientService deleteMessage:messageKey
                                       andContactId:nil
                                     withCompletion:([OCMArg invokeBlockWithArgs:@"success",
                                                      [OCMArg defaultValue],
                                                      nil])]);


    [messageService deleteMessage:messageKey
                     andContactId:nil
                   withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(status);
    }];
}

- (void)test_deleteMessageForMessageKeyIsUnsuccessful_thatErrorIsPresent {

    NSString *messageKey = @"messageKey1";

    OCMStub([mockMessageClientService deleteMessage:messageKey
                                       andContactId:nil
                                     withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                      networkError,
                                                      nil])]);


    [messageService deleteMessage:messageKey
                     andContactId:nil
                   withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(status);
    }];
}

- (void)test_deleteMessageForMessageKeyIsNil {

    NSString *messageKey = nil;
    
    [messageService deleteMessage:messageKey andContactId:nil withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(status);
    }];
}

- (void)test_messageinfoWithMessageKeyIsSuccessful_thatErrorIsNotPresent {

    NSString *messageKey = @"messageKey1";

    ALMessageInfo *messageInfo = [[ALMessageInfo alloc] init];
    messageInfo.status = 1l;
    messageInfo.userId = @"userId1";
    ALMessageInfoResponse *info = [[ALMessageInfoResponse alloc] init];

    NSMutableArray<ALMessageInfo *> *messageArray = [[NSMutableArray alloc] init];
    [messageArray addObject:messageInfo];
    info.msgInfoList = messageArray;

    OCMStub([mockMessageClientService getCurrentMessageInformation:messageKey
                                             withCompletionHandler:([OCMArg invokeBlockWithArgs:info,
                                                                     [OCMArg defaultValue],
                                                                     nil])]);

    [messageService getMessageInformationWithMessageKey:messageKey withCompletionHandler:^(ALMessageInfoResponse *msgInfo, NSError *theError) {
        XCTAssertNil(theError);
        XCTAssertNotNil(msgInfo);
    }];

}

- (void)test_messageinfoWithMessageKeyIsUnsuccessful_thatErrorIsPresent {

    NSString *messageKey = @"messageKey1";

    ALMessageInfo *messageInfo = [[ALMessageInfo alloc] init];
    messageInfo.status = 1l;
    messageInfo.userId = @"userId1";
    ALMessageInfoResponse *info = [[ALMessageInfoResponse alloc] init];

    NSMutableArray<ALMessageInfo *> *messageArray = [[NSMutableArray alloc] init];
    [messageArray addObject:messageInfo];
    info.msgInfoList = messageArray;

    OCMStub([mockMessageClientService getCurrentMessageInformation:messageKey
                                             withCompletionHandler:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                                     networkError,
                                                                     nil])]);

    [messageService getMessageInformationWithMessageKey:messageKey withCompletionHandler:^(ALMessageInfoResponse *msgInfo, NSError *theError) {
        XCTAssertNotNil(theError);
        XCTAssertNil(msgInfo);
    }];

}


- (void)test_messageinfoWithMessageKeyIsUnsuccessful_thatParameterIsNil {

    [messageService getMessageInformationWithMessageKey:nil withCompletionHandler:^(ALMessageInfoResponse *msgInfo, NSError *theError) {
        XCTAssertNotNil(theError);
        XCTAssertNil(msgInfo);
    }];
}

- (void)test_updateMessageMetadataWithMessageKeyIsSuccessful_thatErrorIsNotPresent {

    id mockMessageClientService  = OCMClassMock([ALMessageClientService class]);
    [mockMessageClientService setResponseHandler:mockResponseHandler];
    messageService.messageClientService = mockMessageClientService;

    NSString *messageKey = @"messageKey1";

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setValue:@"value1" forKey:@"key1"];
    [metadata setValue:@"value2" forKey:@"key2"];
    [metadata setValue:@"value3" forKey:@"key3"];

    ALAPIResponse *mockApiResponse = [[ALAPIResponse alloc] init];
    mockApiResponse.generatedAt = @1623926734139;
    mockApiResponse.response = @"success";
    mockApiResponse.status = @"success";

    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setValue:@1623664309876 forKey:@"generatedAt"];
    [jsonDictionary setValue:@"success" forKey:@"status"];

    OCMStub([mockMessageClientService updateMessageMetadataOfKey:messageKey
                                                    withMetadata:metadata
                                                  withCompletion:([OCMArg invokeBlockWithArgs:jsonDictionary,
                                                                   [OCMArg defaultValue],
                                                                   nil])]);
    [messageService updateMessageMetadataOfKey:messageKey
                                  withMetadata:metadata
                                withCompletion:^(ALAPIResponse *theJson, NSError *theError) {
        XCTAssertNil(theError);
        XCTAssertNotNil(theJson);

    }];

}


- (void)test_updateMessageMetadataWithMessageKeyIsUnsuccessful_thatErrorIsPresent {

    id mockMessageClientService  = OCMClassMock([ALMessageClientService class]);
    [mockMessageClientService setResponseHandler:mockResponseHandler];
    messageService.messageClientService = mockMessageClientService;

    NSString *messageKey = @"messageKey1";

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setValue:@"value1" forKey:@"key1"];
    [metadata setValue:@"value2" forKey:@"key2"];
    [metadata setValue:@"value3" forKey:@"key3"];

    ALAPIResponse *mockApiResponse = [[ALAPIResponse alloc] init];
    mockApiResponse.generatedAt = @1623926734139;
    mockApiResponse.response = @"success";
    mockApiResponse.status = @"success";

    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setValue:@1623664309876 forKey:@"generatedAt"];
    [jsonDictionary setValue:@"success" forKey:@"status"];

    OCMStub([mockMessageClientService updateMessageMetadataOfKey:messageKey
                                                    withMetadata:metadata
                                                  withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                                   networkError,
                                                                   nil])]);



    [messageService updateMessageMetadataOfKey:messageKey
                                  withMetadata:metadata
                                withCompletion:^(ALAPIResponse *theJson, NSError *theError) {
        XCTAssertNotNil(theError);
        XCTAssertNil(theJson);
    }];

}

- (void)test_updateMessageMetadataWithMessageKeyIsUnsuccessful_thatParameterIsNil {

    [messageService updateMessageMetadataOfKey:nil
                                  withMetadata:nil
                                withCompletion:^(ALAPIResponse *theJson, NSError *theError) {
        XCTAssertNotNil(theError);
        XCTAssertNil(theJson);
    }];
}


@end
