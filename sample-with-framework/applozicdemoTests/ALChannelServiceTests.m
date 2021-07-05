//
//  ALChannelServiceTests.m
//  applozicdemoTests
//
//  Created by apple on 02/07/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Applozic/Applozic.h>


@interface ALChannelServiceTests : XCTestCase

@end

@implementation ALChannelServiceTests {
    id channelDatabaseServiceMock;
    id channelClientServiceMock;
    ALChannelDBService *channelDBService;
    ALChannelService *channelService;
    NSError *networkError;
}

- (void)setUp {
    channelDatabaseServiceMock = OCMClassMock([ALChannelDBService class]);
    channelClientServiceMock = OCMClassMock([ALChannelClientService class]);

    channelService = [[ALChannelService alloc] init];
    channelService.channelClientService = channelClientServiceMock;
    channelService.channelDBService = channelDatabaseServiceMock;

    networkError = [NSError errorWithDomain:@"Network Error" code:999 userInfo:nil];

}

- (void)test_channelCreateIsUnSuccessful_thatErrorIsPresent {
    ALChannelInfo *channelInfo = [[ALChannelInfo alloc] init];
    channelInfo.groupName = @"channel name";
    channelInfo.clientGroupId = @"client groupId";
    channelInfo.groupMemberList = [[NSMutableArray alloc] initWithObjects:@"user1",@"user2", nil];;

    OCMStub([channelClientServiceMock createChannel:channelInfo.groupName
                                andParentChannelKey:channelInfo.parentKey
                                 orClientChannelKey:channelInfo.clientGroupId
                                     andMembersList:channelInfo.groupMemberList
                                       andImageLink:channelInfo.imageUrl
                                        channelType:channelInfo.type
                                        andMetaData:channelInfo.metadata
                                          adminUser:channelInfo.admin
                                     withGroupUsers:channelInfo.groupRoleUsers
                                     withCompletion:([OCMArg invokeBlockWithArgs:networkError,
                                                      [NSNull null],
                                                      nil])]);

    [channelService createChannelWithChannelInfo:channelInfo
                                  withCompletion:^(ALChannelCreateResponse *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];

}

- (void)test_channelCreateIsSuccessful_thatErrorIsNotPresent {

    ALChannelInfo *channelInfo = [[ALChannelInfo alloc] init];
    channelInfo.groupName = @"channel name";
    channelInfo.clientGroupId = @"client groupId";
    channelInfo.groupMemberList = [[NSMutableArray alloc] initWithObjects:@"user1",@"user2", nil];

    ALChannel *channel = [[ALChannel alloc] init];
    channel.key = @1234;
    channel.name = channelInfo.groupName;
    channel.clientChannelKey = channelInfo.clientGroupId;

    NSMutableArray *groupUserArray = [[NSMutableArray alloc] init];

    ALGroupUser *groupUser = [[ALGroupUser alloc] init];
    groupUser.groupRole = @1;
    groupUser.userId = @"userId1";
    [groupUserArray addObject:groupUser];

    channel.groupUsers = groupUserArray;

    ALChannelCreateResponse *channelResponse = [[ALChannelCreateResponse alloc] init];
    channelResponse.alChannel = channel;
    channelResponse.generatedAt = @1623926734139;
    channelResponse.response = @"success";
    channelResponse.status = @"success";


    OCMStub([channelClientServiceMock createChannel:channelInfo.groupName
                                andParentChannelKey:channelInfo.parentKey
                                 orClientChannelKey:channelInfo.clientGroupId
                                     andMembersList:channelInfo.groupMemberList
                                       andImageLink:channelInfo.imageUrl
                                        channelType:channelInfo.type
                                        andMetaData:channelInfo.metadata
                                          adminUser:channelInfo.admin
                                     withGroupUsers:channelInfo.groupRoleUsers
                                     withCompletion:([OCMArg invokeBlockWithArgs:
                                                      [NSNull null],
                                                      channelResponse, nil])]);

    [channelService createChannelWithChannelInfo:channelInfo
                                  withCompletion:^(ALChannelCreateResponse *response, NSError *error) {
        XCTAssertNotNil(response);
        XCTAssertNil(error);
    }];

}

- (void)test_whenMarkConversationIsSuccessful_thatErrorIsNotPresent {

    OCMStub([channelDatabaseServiceMock markConversationAsRead:@123 ]).andReturn(5);

    OCMStub([channelClientServiceMock markConversationAsRead:@123
                                              withCompletion:([OCMArg invokeBlockWithArgs:@"success", [OCMArg defaultValue], nil])]);

    [channelService markConversationAsRead:@123 withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
        XCTAssertEqual(@"success", response);
    }];

}

- (void)test_whenMarkConversationIsUnsuccessful_thatErrorIsPresent {
    OCMStub([channelDatabaseServiceMock markConversationAsRead:@123 ]).andReturn(5);

    OCMStub([channelClientServiceMock markConversationAsRead:@123
                                              withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue], networkError , nil])]);

    [channelService markConversationAsRead:@123 withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

- (void)test_whenMarkConversationChannelKeyIsNil {
    [channelService markConversationAsRead:nil withCompletion:^(NSString *response, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

- (void)test_muteUserIsUnsuccessful_thatErrorIsPresent {
    ALMuteRequest *alMuteRequest = [ALMuteRequest new];
    alMuteRequest.clientGroupId = @"clientGroupId";
    long currentTimeStemp = [[NSNumber numberWithLong:([[NSDate date] timeIntervalSince1970]*1000)] longValue];
    alMuteRequest.notificationAfterTime = [NSNumber numberWithLong:(currentTimeStemp + 8*60*60*1000)];;

    OCMStub([channelClientServiceMock muteChannel:alMuteRequest
                                   withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                    networkError,
                                                    nil])]);
    [channelService muteChannel:alMuteRequest
                 withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}


- (void)test_muteChannelIsUnsuccessful_thatRequestIsNil {
    ALMuteRequest *alMuteRequest = [ALMuteRequest new];
    alMuteRequest.userId = nil;
    [channelService muteChannel:alMuteRequest
                 withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(apiResponse);
    }];
}

- (void)test_muteChannelIsSuccessful_thatErrorIsNotPresent {
    ALMuteRequest *alMuteRequest = [ALMuteRequest new];
    alMuteRequest.clientGroupId = @"clientGroupId";
    long currentTimeStemp = [[NSNumber numberWithLong:([[NSDate date] timeIntervalSince1970]*1000)] longValue];
    alMuteRequest.notificationAfterTime = [NSNumber numberWithLong:(currentTimeStemp + 8*60*60*1000)];

    ALAPIResponse *apiResponseMock = [[ALAPIResponse alloc] init];
    apiResponseMock.generatedAt = @1623926734139;
    apiResponseMock.response = @"success";
    apiResponseMock.status = @"success";

    OCMStub([channelClientServiceMock muteChannel:alMuteRequest
                                   withCompletion:([OCMArg invokeBlockWithArgs:apiResponseMock,
                                                    [OCMArg defaultValue],
                                                    nil])]);
    [channelService muteChannel:alMuteRequest
                 withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(apiResponse);
    }];
}

- (void)test_addMemberToChannelIsUnsuccessful_theErrorIsPresent {

    OCMStub([channelClientServiceMock addMemberToChannel:@"user1"
                                      orClientChannelKey:nil
                                           andChannelKey:@123
                                          withCompletion:([OCMArg invokeBlockWithArgs:networkError,
                                                           [OCMArg defaultValue],
                                                           nil])]);

    [channelService addMemberToChannel:@"user1"
                         andChannelKey:@123
                    orClientChannelKey:nil
                        withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];

}


- (void)test_addMemberToChannelIsSuccessful_theErrorIsNotPresent {

    ALAPIResponse *apiResponseMock = [[ALAPIResponse alloc] init];
    apiResponseMock.generatedAt = @1623926734139;
    apiResponseMock.response = @"success";
    apiResponseMock.status = @"success";


    OCMStub([channelClientServiceMock addMemberToChannel:@"user1"
                                      orClientChannelKey:nil
                                           andChannelKey:@123
                                          withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                           apiResponseMock,
                                                           nil])]);

    [channelService addMemberToChannel:@"user1"
                         andChannelKey:@123
                    orClientChannelKey:nil
                        withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
    }];
}

-(void)test_addMemberToChannelIsUnsuccessful_theParameterIsNil {

    [channelService addMemberToChannel:nil
                         andChannelKey:nil
                    orClientChannelKey:nil
                        withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}

- (void)test_removeMemberToChannelIsUnsuccessful_theErrorIsPresent {

    OCMStub([channelClientServiceMock removeMemberFromChannel:@"user1"
                                           orClientChannelKey:nil
                                                andChannelKey:@123
                                               withCompletion:([OCMArg invokeBlockWithArgs:networkError,
                                                                [OCMArg defaultValue],
                                                                nil])]);

    [channelService removeMemberFromChannel:@"user1"
                              andChannelKey:@123
                         orClientChannelKey:nil
                             withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}


- (void)test_removeMemberToChannelIsSuccessful_theErrorIsNotPresent {

    ALAPIResponse *apiResponseMock = [[ALAPIResponse alloc] init];
    apiResponseMock.generatedAt = @1623926734139;
    apiResponseMock.response = @"success";
    apiResponseMock.status = @"success";


    OCMStub([channelClientServiceMock removeMemberFromChannel:@"user1"
                                           orClientChannelKey:nil
                                                andChannelKey:@123
                                               withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                                apiResponseMock,
                                                                nil])]);

    [channelService removeMemberFromChannel:@"user1"
                              andChannelKey:@123
                         orClientChannelKey:nil
                             withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
    }];
}


-(void)test_removeMemberToChannelIsUnsuccessful_theParameterIsNil {

    [channelService removeMemberFromChannel:nil
                              andChannelKey:nil
                         orClientChannelKey:nil
                             withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}


- (void)test_deleteChannelIsUnsuccessful_theErrorIsPresent {

    OCMStub([channelClientServiceMock deleteChannel:@123
                                 orClientChannelKey:nil
                                     withCompletion:([OCMArg invokeBlockWithArgs:networkError,
                                                      [OCMArg defaultValue],
                                                      nil])]);

    [channelService deleteChannel:@123
               orClientChannelKey:nil
                   withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}


- (void)test_deleteChannelIsSuccessful_theErrorIsNotPresent {
    ALAPIResponse *apiResponseMock = [[ALAPIResponse alloc] init];
    apiResponseMock.generatedAt = @1623926734139;
    apiResponseMock.response = @"success";
    apiResponseMock.status = @"success";


    OCMStub([channelClientServiceMock deleteChannel:@123
                                 orClientChannelKey:nil
                                     withCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                      apiResponseMock,
                                                      nil])]);

    [channelService deleteChannel:@123
               orClientChannelKey:nil
                   withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNil(error);
        XCTAssertNotNil(response);
    }];
}


- (void)test_deleteChannelIsUnsuccessful_theParameterIsNil {

    [channelService deleteChannel:nil
               orClientChannelKey:nil
                   withCompletion:^(NSError *error, ALAPIResponse *response) {
        XCTAssertNotNil(error);
        XCTAssertNil(response);
    }];
}




- (void)test_updateMetadataChannelIsUnsuccessful_theErrorIsPresent {

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setValue:@"value1" forKey:@"key1"];
    [metadata setValue:@"value2" forKey:@"key2"];
    [metadata setValue:@"value3" forKey:@"key3"];

    OCMStub([channelClientServiceMock updateChannelMetaData:@123
                                         orClientChannelKey:nil
                                                   metadata:metadata
                                              andCompletion:([OCMArg invokeBlockWithArgs:networkError,
                                                              [OCMArg defaultValue],
                                                              nil])]);


    [channelService updateChannelMetaData:@123
                       orClientChannelKey:nil
                                 metadata:metadata
                           withCompletion:^(NSError *error) {
        XCTAssertNotNil(error);
    }];
}


- (void)test_updateMetadataChannelIsSuccessful_theErrorIsNotPresent {

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setValue:@"value1" forKey:@"key1"];
    [metadata setValue:@"value2" forKey:@"key2"];
    [metadata setValue:@"value3" forKey:@"key3"];

    ALAPIResponse *apiResponseMock = [[ALAPIResponse alloc] init];
    apiResponseMock.generatedAt = @1623926734139;
    apiResponseMock.response = @"success";
    apiResponseMock.status = @"success";


    OCMStub([channelClientServiceMock updateChannelMetaData:@123
                                         orClientChannelKey:nil
                                                   metadata:metadata
                                              andCompletion:([OCMArg invokeBlockWithArgs:[OCMArg defaultValue],
                                                              apiResponseMock,
                                                              nil])]);


    [channelService updateChannelMetaData:@123
                       orClientChannelKey:nil
                                 metadata:metadata
                           withCompletion:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)test_updateMetadataChannelIsUnsuccessful_theParameterIsNil {

    [channelService updateChannelMetaData:nil
                       orClientChannelKey:nil
                                 metadata:nil
                           withCompletion:^(NSError *error) {
        XCTAssertNotNil(error);
    }];
}


@end
