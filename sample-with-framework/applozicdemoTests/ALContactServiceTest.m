//
//  ALContactServiceTest.m
//  applozicdemoTests
//
//  Created by apple on 01/07/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Applozic/Applozic.h>

@interface ALContactServiceTest : XCTestCase

@end

@implementation ALContactServiceTest {
    id contactDBServiceMock;
    ALContactDBService *contactDBService;
    ALContactService *contactService;
}

- (void)setUp {
    contactDBServiceMock = OCMClassMock([ALContactDBService class]);
    contactService = [[ALContactService alloc] init];
    contactService.alContactDBService = contactDBServiceMock;
    contactDBService = [[ALContactDBService alloc] init];
}

- (void)tearDown {
    [contactDBServiceMock stopMocking];
}

- (void)test_addContact_successfull {
    ALContact *contact = [[ALContact alloc] init];
    contact.userId = @"userId";
    contact.displayName = @"user display name";
    OCMStub([contactDBServiceMock addContactInDatabase:contact]).andReturn(YES);
    BOOL success = [contactService addContact:contact];
    XCTAssertTrue(success);
}

- (void)test_addContact_theValueIsNil {
    ALContact *contact = [[ALContact alloc] init];
    contact.userId = nil;
    BOOL failed = [contactService addContact:contact];
    XCTAssertFalse(failed);
}

- (void)test_updateContact_successfull {
    ALContact *contact = [[ALContact alloc] init];
    contact.userId = @"userId";
    contact.displayName = @"user display name";
    OCMStub([contactDBServiceMock updateContactInDatabase:contact]).andReturn(YES);
    BOOL success = [contactService updateContact:contact];
    XCTAssertTrue(success);
}

- (void)test_updateContact_theValueIsNil {
    ALContact *contact = [[ALContact alloc] init];
    contact.userId = nil;
    BOOL failed = [contactService updateContact:contact];
    XCTAssertFalse(failed);
}

- (void)test_loadContact_successfull {
    
    ALContact *contact = [[ALContact alloc] init];
    contact.userId = @"userId";
    contact.displayName = @"user display name";
    OCMStub([contactDBServiceMock loadContactByKey:@"userId" value:@"userId1"]).andReturn(contact);
    ALContact *mockContact = [contactService loadContactByKey:@"userId" value:@"userId1"];
    XCTAssertEqual(contact.userId, mockContact.userId);
}

- (void)test_loadContact_theValueIsNil {
    ALContact *mockContact = [contactService loadContactByKey:nil value:nil];
    XCTAssertNil(mockContact);
}

- (void)test_userDeleted_theValueIsNil {
    BOOL failed = [contactService isUserDeleted:nil];
    XCTAssertFalse(failed);
}

- (void)test_userDeleted_successfull {
    OCMStub([contactDBServiceMock isUserDeleted:@"userId1"]).andReturn(YES);
    BOOL success = [contactService isUserDeleted:@"userId1"];
    XCTAssertTrue(success);
}

- (void)test_updateArrayOfContacts_successfull {
    ALContact *contact = [[ALContact alloc] init];
    contact.userId = @"userId";
    contact.displayName = @"user display name";
    NSArray *contactArray = @[
        contact];
    OCMStub([contactDBServiceMock updateListOfContacts:contactArray]).andReturn(YES);
    BOOL success = [contactService updateListOfContacts:contactArray];
    XCTAssertTrue(success);
}

- (void)test_updateArrayOfContacts_theValueIsNil {
    NSArray *contactArray = @[];
    BOOL failed = [contactService updateListOfContacts:contactArray];
    XCTAssertFalse(failed);
}


@end
