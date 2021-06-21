//
//  ALUserServiceTest.m
//  applozicdemoTests
//
//  Created by Sunil on 18/06/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Applozic/Applozic.h>
#import <OCMock/OCMock.h>

@interface ALUserServiceTest : XCTestCase

@end

@implementation ALUserServiceTest {
    id userServiceMock;
    id userClientServiceMock;
    id contactServiceMock;
    id contactDataBaseMock;
    id responseHandlerMock;
    ALUserClientService *userClientService;
    ALUserService *userService;
    NSError *testError;
    ALMessage *testMessage;
}

- (void)setUp {
    
    testError = [NSError errorWithDomain:@"Network Error" code:999 userInfo:nil];
    userServiceMock = OCMClassMock([ALUserService class]);
    userClientServiceMock = OCMClassMock([ALUserClientService class]);
    contactDataBaseMock = OCMClassMock([ALContactDBService class]);
    contactServiceMock = OCMClassMock([ALContactService class]);
    responseHandlerMock = OCMClassMock([ALResponseHandler class]);
    
    userService = [[ALUserService alloc] init];
    [userClientServiceMock setResponseHandler:responseHandlerMock];
    userService.userClientService = userClientServiceMock;
    userService.contactService = contactServiceMock;
    userService.contactDBService = contactDataBaseMock;
    
    testMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
        alMessageBuilder.to = @"userId";
        alMessageBuilder.message = @"messageText";
    }];
    
}

- (void)tearDown {
    [userServiceMock stopMocking];
    [userClientServiceMock stopMocking];
    [responseHandlerMock stopMocking];
    [contactServiceMock stopMocking];
    [contactDataBaseMock stopMocking];
    [super tearDown];
}


- (void)test_whenMarkConversationIsSuccessful_thatErrorIsNotPresent {
    OCMStub([userServiceMock markConversationAsRead:@"userId" withCompletion:(@"success", [OCMArg defaultValue], nil)]);
    
    OCMStub([contactDataBaseMock markConversationAsDeliveredAndRead:@"userId"]).andReturn(5);
    
    
    OCMStub([userClientServiceMock markConversationAsReadforContact:@"userId" withCompletion:([OCMArg invokeBlockWithArgs:@"success", [OCMArg defaultValue], nil])]);
    
    [userService markConversationAsRead:@"userId" withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
        XCTAssertEqual(@"success", response);
    }];
}

- (void)test_whenMarkConversationIsUnsuccessful_thatErrorIsPresent {
    
    OCMStub([userServiceMock markConversationAsRead:@"userId" withCompletion:([OCMArg defaultValue], testError, nil)]);
    
    OCMStub([contactDataBaseMock markConversationAsDeliveredAndRead:@"userId"]).andReturn(5);
    
    OCMStub([userClientServiceMock markConversationAsReadforContact:@"userId" withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], testError, nil])]);
    
    [userService markConversationAsRead:@"userId" withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

- (void)test_whenMarkConversationUserIdIsNil {
    [userService markConversationAsRead:nil withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

- (void)test_whenMessageReportedIsUnsuccessful_whenErrorIsPresent  {
    
    OCMStub([userClientServiceMock reportUserWithMessageKey:@"messageKey1" withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], testError, nil])]);
    
    [userService reportUserWithMessageKey:@"messageKey1" withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
    }];
}


- (void)test_whenMessageReportedIsSuccessful_whenErrorIsNotPresent {
    
    ALAPIResponse *apiResponseMock = [[ALAPIResponse alloc] init];
    apiResponseMock.generatedAt = @1623926734139;
    apiResponseMock.response = @"success";
    apiResponseMock.status = @"success";
    
    OCMStub([userClientServiceMock reportUserWithMessageKey:@"messageKey1" withCompletion:([OCMArg invokeBlockWithArgs:apiResponseMock, [OCMArg defaultValue], nil])]);
    
    [userService reportUserWithMessageKey:@"messageKey1" withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(apiResponse);
    }];
}

- (void)test_whenMessageReported_thatMessageKeyIsNil {
    [userService reportUserWithMessageKey:nil withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
    }];
}


- (void)test_blockTheUserIsUnsuccessful_thatErrorIsPresent {
    OCMStub([userClientServiceMock userBlockServerCall:@"userId"
                                        withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], testError, nil])]);
    
    [userService blockUser:@"userId" withCompletionHandler:^(NSError *error, BOOL userBlock) {
        XCTAssertNotNil(error);
    }];
}

- (void)test_blockTheUserIsSuccessful_thatErrorIsNotPresent {
    
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    
    [jsonDictionary setValue:@1624014207855 forKey:@"generatedAt"];
    [jsonDictionary setObject:@"success" forKey:@"response"];
    [jsonDictionary setValue:@"success" forKey:@"status"];
    
    OCMStub([userClientServiceMock userBlockServerCall:@"userId"
                                        withCompletion:([OCMArg invokeBlockWithArgs:jsonDictionary, [OCMArg defaultValue], nil])]);
    
    [userService blockUser:@"userId" withCompletionHandler:^(NSError *error, BOOL userBlock) {
        XCTAssertNil(error);
        XCTAssertTrue(userBlock);
    }];
}

- (void)test_blockTheUserIsUnsuccessful_userIdIsNil {
    [userService blockUser:nil withCompletionHandler:^(NSError *error, BOOL userBlock) {
        XCTAssertNotNil(error);
    }];
}

- (void)test_unblockTheUserIsUnsuccessful_thatErrorIsPresent {
    OCMStub([userClientServiceMock userBlockServerCall:@"userId"
                                        withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], testError, nil])]);
    
    [userService unblockUser:@"userId" withCompletionHandler:^(NSError *error, BOOL userBlock) {
        XCTAssertNotNil(error);
    }];
}


- (void)test_unblockTheUserIsSuccessful_thatErrorIsNotPresent {
    
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    
    [jsonDictionary setValue:@1624014207855 forKey:@"generatedAt"];
    
    [jsonDictionary setObject:@"success" forKey:@"response"];
    [jsonDictionary setValue:@"success" forKey:@"status"];
    
    OCMStub([userClientServiceMock userUnblockServerCall:@"userId"
                                          withCompletion:([OCMArg invokeBlockWithArgs:jsonDictionary, [OCMArg defaultValue], nil])]);
    
    [userService unblockUser:@"userId" withCompletionHandler:^(NSError *error, BOOL userBlock) {
        XCTAssertNil(error);
        XCTAssertTrue(userBlock);
    }];
}

- (void)test_unblockTheUserIsUnsuccessful_userIdIsNil {
    [userService unblockUser:nil withCompletionHandler:^(NSError *error, BOOL userBlock) {
        XCTAssertNotNil(error);
    }];
}

- (void)test_updatePasswordIsSuccessful_thatErrorIsNotPresent {
    ALAPIResponse *mockApiResponse = [[ALAPIResponse alloc] init];
    mockApiResponse.generatedAt = @1623926734139;
    mockApiResponse.response = @"success";
    mockApiResponse.status = @"success";
    
    OCMStub([userClientServiceMock updatePassword:@"oldPassword" withNewPassword:@"newPassword"
                                   withCompletion:([OCMArg invokeBlockWithArgs:mockApiResponse, [OCMArg defaultValue], nil])]);
    
    [userService updatePassword:@"oldPassword" withNewPassword:@"newPassword" withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(apiResponse);
    }];
}

- (void)test_updatePasswordIsUnsuccessful_thatErrorIsPresent {
    
    OCMStub([userClientServiceMock updatePassword:@"oldPassword" withNewPassword:@"newPassword"
                                   withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], testError, nil])]);
    
    [userService updatePassword:@"oldPassword" withNewPassword:@"newPassword" withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}

- (void)test_updatePasswordIsUnsuccessful_thePasswordsAreNil {
    [userService updatePassword:nil withNewPassword:nil withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}

- (void)test_listOfUsersWithNameIsSuccessful_thatErrorIsNotPresent {
    ALAPIResponse *mockApiResponse = [[ALAPIResponse alloc] init];
    mockApiResponse.generatedAt = @1623926734139;
    mockApiResponse.status = @"success";
    
    OCMStub([userClientServiceMock getListOfUsersWithUserName:@"testName"
                                               withCompletion:([OCMArg invokeBlockWithArgs:mockApiResponse, [OCMArg defaultValue], nil])]);
    
    [userService getListOfUsersWithUserName:@"testName" withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(apiResponse);
    }];
}

- (void)test_listOfUsersWithNameIsUnsuccessful_thatErrorIsPresent {
    
    OCMStub([userClientServiceMock getListOfUsersWithUserName:@"testName"
                                               withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], testError, nil])]);
    
    [userService getListOfUsersWithUserName:@"testName" withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}

- (void)test_listOfUsersWithNameIsUnsuccessful_thatUserNameIsNil {
    [userService getListOfUsersWithUserName:nil withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}

- (void)test_muteUserIsUnsuccessful_thatErrorIsPresent {
    ALMuteRequest *alMuteRequest = [ALMuteRequest new];
    alMuteRequest.userId = @"userId";
    long currentTimeStemp = [[NSNumber numberWithLong:([[NSDate date] timeIntervalSince1970]*1000)] longValue];
    alMuteRequest.notificationAfterTime = [NSNumber numberWithLong:(currentTimeStemp + 8*60*60*1000)];;
    
    OCMStub([userClientServiceMock muteUser:alMuteRequest
                             withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                              testError,
                                              nil])]);
    [userService muteUser:alMuteRequest
           withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}


- (void)test_muteUserIsUnsuccessful_thatRequestIsNil {
    ALMuteRequest *alMuteRequest = [ALMuteRequest new];
    alMuteRequest.userId = nil;
    [userService muteUser:alMuteRequest
           withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}

- (void)test_muteUserIsSuccessful_thatErrorIsNotPresent {
    ALMuteRequest *alMuteRequest = [ALMuteRequest new];
    alMuteRequest.userId = @"userId";
    long currentTimeStemp = [[NSNumber numberWithLong:([[NSDate date] timeIntervalSince1970]*1000)] longValue];
    alMuteRequest.notificationAfterTime = [NSNumber numberWithLong:(currentTimeStemp + 8*60*60*1000)];
    
    ALAPIResponse *apiResponseMock = [[ALAPIResponse alloc] init];
    apiResponseMock.generatedAt = @1623926734139;
    apiResponseMock.response = @"success";
    apiResponseMock.status = @"success";
    
    OCMStub([userClientServiceMock muteUser:alMuteRequest
                             withCompletion:([OCMArg invokeBlockWithArgs:apiResponseMock,
                                              [OCMArg defaultValue],
                                              nil])]);
    [userService muteUser:alMuteRequest
           withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(apiResponse);
    }];
}

- (void)test_markMessageAsReadIsUnsuccessful_thatErrorIsPresent {
    OCMStub([userClientServiceMock markMessageAsReadforPairedMessageKey:@"messageKey1"
                                                         withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                                          testError,
                                                                          nil])]);
    
    [userService markMessageAsRead:testMessage withPairedkeyValue:@"messageKey1" withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(status);
    }];
}


- (void)test_markMessageAsReadIsSuccessful_thatErrorIsNotPresent {
    
    OCMStub([userClientServiceMock markMessageAsReadforPairedMessageKey:@"messageKey1"
                                                         withCompletion:([OCMArg invokeBlockWithArgs:@"success",
                                                                          [OCMArg defaultValue],
                                                                          nil])]);
    
    [userService markMessageAsRead:testMessage withPairedkeyValue:@"messageKey1" withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(status);
    }];
}

- (void)test_markMessageAsReadIsUnsuccessful_theParametersAreNil {
    
    OCMStub([userClientServiceMock markMessageAsReadforPairedMessageKey:nil
                                                         withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                                          [OCMArg defaultValue],
                                                                          nil])]);
    
    [userService markMessageAsRead:nil withPairedkeyValue:nil withCompletion:^(NSString *status, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(status);
    }];
}

- (void)test_updateLoginUserDetailUnsuccessful_theParametersAreNil {
    
    [userService updateUserDisplayName:nil andUserImage:nil userStatus:nil withCompletion:^(id theJson, NSError *error) {
        XCTAssertNotNil(error);
    }];
}

- (void)test_updateLoginUserDetailIsSuccessful_theErrorIsNotPresent {
    
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    
    [jsonDictionary setValue:@1623664309876 forKey:@"generatedAt"];
    [jsonDictionary setObject:@"success" forKey:@"response"];
    [jsonDictionary setValue:@"success" forKey:@"status"];
    
    OCMStub([userClientServiceMock updateUserDisplayName:@"DisplayName"
                                        andUserImageLink:@"https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/master/macbookpro.jpg"
                                              userStatus:@""
                                                metadata:nil
                                          withCompletion:([OCMArg invokeBlockWithArgs:jsonDictionary,
                                                           [OCMArg defaultValue],
                                                           nil])]);
    
    [userService updateUserDisplayName:@"DisplayName"
                          andUserImage:@"https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/master/macbookpro.jpg"
                            userStatus:@"" withCompletion:^(id theJson, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(theJson);
    }];
}

- (void)test_updateLoginUserDetailIsUnsuccessful_theErrorIsPresent {
    
    OCMStub([userClientServiceMock updateUserDisplayName:@"DisplayName"
                                        andUserImageLink:@"https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/master/macbookpro.jpg"
                                              userStatus:@""
                                                metadata:nil
                                          withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                           testError,
                                                           nil])]);
    
    [userService updateUserDisplayName:@"DisplayName"
                          andUserImage:@"https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/master/macbookpro.jpg"
                            userStatus:@"" withCompletion:^(id theJson, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(theJson);
    }];
}

- (void)test_mutedUserLisIsUnsuccessful_theErrorIsPresent {
    
    OCMStub([userClientServiceMock getMutedUserListWithCompletion:
             ([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
               testError,
               nil])]);
    
    [userService getMutedUserListWithDelegate:nil withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(userDetailArray);
    }];
}


- (void)test_mutedUserLisIsSuccessful_theErrorIsNotPresent {
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setValue:@"userID1" forKey:@"userId"];
    [userDictionary setValue:@"displayName1" forKey:@"displayName"];
    [userDictionary setValue:@"imageLink1" forKey:@"imageLink"];
    [userDictionary setValue:@1623664309876 forKey:@"lastSeenAtTime"];
    
    ALUserDetail *userDetail = [[ALUserDetail alloc] initWithDictonary:userDictionary];
    
    NSArray *jsonUserDetailsArray = [[NSArray alloc] initWithObjects:userDictionary, nil];
    
    OCMStub([userClientServiceMock getMutedUserListWithCompletion:
             ([OCMArg invokeBlockWithArgs:jsonUserDetailsArray,
               [OCMArg defaultValue],
               nil])]);
    
    NSMutableArray *userDetailArray = [[NSMutableArray alloc] init];
    [userDetailArray addObject:userDetail];
    
    OCMStub([contactDataBaseMock addMuteUserDetailsWithDelegate:nil withNSDictionary:(NSMutableDictionary*)jsonUserDetailsArray]).andReturn(userDetailArray);
    
    [userService getMutedUserListWithDelegate:nil
                               withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(userDetailArray);
    }];
}


@end
