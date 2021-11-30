//
//  ALUserService.m
//  Applozic
//
//  Created by Divjyot Singh on 05/11/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

static int CONTACT_PAGE_SIZE = 100;

#import "ALApplozicSettings.h"
#import "ALContactDBService.h"
#import "ALContactService.h"
#import "ALLastSeenSyncFeed.h"
#import "ALLogger.h"
#import "ALMessageClientService.h"
#import "ALMessageDBService.h"
#import "ALMessageList.h"
#import "ALMessageService.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "ALSyncMessageFeed.h"
#import "ALUser.h"
#import "ALUserClientService.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserDetail.h"
#import "ALUserService.h"
#import "ALUtilityClass.h"
#import "NSString+Encode.h"
#import "ALVerification.h"

@implementation ALUserService
{
}

+ (ALUserService *)sharedInstance {
    static ALUserService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ALUserService alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupServices];
    }
    return self;
}

#pragma mark - Setup services

- (void)setupServices {
    self.userClientService = [[ALUserClientService alloc] init];
    self.channelService = [[ALChannelService alloc] init];
    self.contactDBService = [[ALContactDBService alloc] init];
    self.contactService = [[ALContactService alloc] init];
}

#pragma mark - Fetch users from messages

- (void)processContactFromMessages:(NSArray *)messages withCompletion:(void(^)(void))completionMark {

    if (messages.count == 0) {
        completionMark();
        return;
    }
    NSMutableOrderedSet *contactIdsArray = [[NSMutableOrderedSet alloc] init ];
    
    for (ALMessage *message in messages) {
        NSString *contactId = message.contactIds;
        if (contactId.length > 0 && ![self.contactService isContactExist:contactId]) {
            [contactIdsArray addObject:contactId];
        }
    }
    
    if ([contactIdsArray count] == 0) {
        completionMark();
        return;
    }
    
    NSMutableArray *userIdArray = [NSMutableArray arrayWithArray:[contactIdsArray array]];
    [self getUserDetails:userIdArray withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
        completionMark();
    }];
}

#pragma mark - Fetch last seen status of users

- (void)getLastSeenUpdateForUsers:(NSNumber *)lastSeenAtTime withCompletion:(void(^)(NSMutableArray *userDetailArray))completionMark {
    
    [self.userClientService userLastSeenDetail:lastSeenAtTime withCompletion:^(ALLastSeenSyncFeed *lastSeenSyncFeed) {
        NSMutableArray *lastSeenUpdateArray = lastSeenSyncFeed.lastSeenArray;
        for (ALUserDetail *userDetail in lastSeenUpdateArray) {
            userDetail.unreadCount = 0;
            [self.contactDBService updateUserDetail:userDetail];
        }
        completionMark(lastSeenUpdateArray);
    }];
}

- (void)userDetailServerCall:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark {
    
    if (!userId) {
        completionMark(nil);
        return;
    }
    
    [self.userClientService userDetailServerCall:userId withCompletion:^(ALUserDetail *userDetail) {
        completionMark(userDetail);
    }];
}

#pragma mark - Update user detail

- (void)updateUserDetail:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark {

    [self getUserDetailFromServer:userId
                   withCompletion:^(ALContact *contact, NSError *error) {

        if (error) {
            completionMark(nil);
            return;
        }

        ALUserDetail *userDetail = [self getUserDetailFromContact:contact];
        completionMark(userDetail);
    }];
}

- (ALUserDetail *)getUserDetailFromContact:(ALContact *)contact {
    ALUserDetail *userDetail = [[ALUserDetail alloc] init];
    userDetail.userId = contact.userId;
    userDetail.contactNumber = contact.contactNumber;
    userDetail.imageLink = contact.contactImageUrl;
    userDetail.displayName = [contact getDisplayName];
    userDetail.connected = contact.connected;
    userDetail.deletedAtTime = contact.deletedAtTime;
    userDetail.roleType = contact.roleType;
    userDetail.notificationAfterTime = contact.notificationAfterTime;
    userDetail.lastSeenAtTime = contact.lastSeenAt;
    userDetail.deletedAtTime = contact.deletedAtTime;
    return userDetail;
}

#pragma mark - Update phone number, email of user with admin user

- (void)updateUser:(NSString *)phoneNumber email:(NSString *)email ofUser:(NSString *)userId withCompletion:(void (^)(BOOL))completion {
    [self.userClientService updateUser:phoneNumber email:email ofUser:userId withCompletion:^(id jsonResponse, NSError *error) {
        if (jsonResponse) {
            /// Updation success.
            ALContact *contact = [self.contactService loadContactByKey:@"userId" value:userId];
            if (!contact) {
                completion(NO);
                return;
            }
            if (email) {
                [contact setEmail:email];
            }
            if (phoneNumber) {
                [contact setContactNumber:phoneNumber];
            }
            BOOL updateStatus = [self.contactDBService updateContactInDatabase:contact];

            [ALVerification verify:updateStatus withErrorMessage:@"Failed to update user details got some error saving in database."];
            completion(updateStatus);
            return;
        }
        completion(NO);
    }];
}

- (void)updateUserDisplayName:(ALContact *)contact {
    if (contact.userId && contact.displayName) {
        [self.userClientService updateUserDisplayName:contact withCompletion:^(id jsonResponse, NSError *error) {
            
            if (error) {
                ALSLog(ALLoggerSeverityError, @"GETTING ERROR in SEVER CALL FOR DISPLAY NAME");
            } else {
                ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
                ALSLog(ALLoggerSeverityInfo, @"RESPONSE_STATUS :: %@", apiResponse.status);
            }
        }];
    }
}

#pragma mark - Update display name user who is not registered

- (void)updateDisplayNameWith:(NSString *)userId
              withDisplayName:(NSString *)displayName
               withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error)) completion {
    
    if (userId.length == 0 || displayName.length == 0) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"UserId or display name details is missing" forKey:NSLocalizedDescriptionKey]];
        completion(nil, error);
        return;
    }
    
    ALContact *contact = [[ALContact alloc] init];
    contact.userId = userId;
    contact.displayName = displayName;
    
    [self.userClientService updateUserDisplayName:contact withCompletion:^(id jsonResponse, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"GETTING ERROR in SEVER CALL FOR DISPLAY NAME");
            completion(nil, error);
        } else {
            ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_STATUS :: %@", apiResponse.status);
            completion(apiResponse, nil);
        }
    }];
}

#pragma mark - Mark Conversation as read

- (void)markConversationAsRead:(NSString *)userId withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    
    if (!userId) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"Failed to mark conversation read userId is nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, error);
        return;
    }
    
    [self setUnreadCountZeroForContactId:userId];
    
    NSUInteger count = [self.contactDBService markConversationAsDeliveredAndRead:userId];
    ALSLog(ALLoggerSeverityInfo, @"Found %ld messages for marking as read.", (unsigned long)count);
    
    if (count == 0) {
        completion(AL_RESPONSE_SUCCESS, nil);
        return;
    }
    [self.userClientService markConversationAsReadforContact:userId withCompletion:^(NSString *response, NSError *error) {
        completion(response,error);
    }];
    
}

- (void)setUnreadCountZeroForContactId:(NSString *)contactId {
    ALContact *contact = [self.contactService loadContactByKey:@"userId" value:contactId];
    contact.unreadCount = [NSNumber numberWithInt:0];
    [self.contactService setUnreadCountInDB:contact];
}

#pragma mark - Mark message as read

- (void)markMessageAsRead:(ALMessage *)message
       withPairedkeyValue:(NSString *)pairedkeyValue
           withCompletion:(void (^)(NSString *, NSError *))completion {
    
    if (!message) {
        NSError *apiError = [NSError
                             errorWithDomain:@"Applozic"
                             code:1
                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to mark message as read ALMessage passed as nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, apiError);
        return;
    }
    
    if (pairedkeyValue.length == 0) {
        NSError *apiError = [NSError
                             errorWithDomain:@"Applozic"
                             code:1
                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to mark message as read pairedMessageKey passed as nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, apiError);
        return;
    }
    
    
    [self markConversationReadInDataBaseWithMessage:message];
    //Server Call
    [self.userClientService markMessageAsReadforPairedMessageKey:pairedkeyValue withCompletion:^(NSString *response, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Response Marking Message :%@",response);
        
        if ([response isEqualToString:AL_RESPONSE_SUCCESS]) {
            completion(response, nil);
        } else {
            NSError *apiError = [NSError
                                 errorWithDomain:@"Applozic"
                                 code:1
                                 userInfo:[NSDictionary dictionaryWithObject:@"Failed to mark message as read an api error occurred" forKey:NSLocalizedDescriptionKey]];
            completion(nil, apiError);
            return;
        }
    }];
}

- (void)markConversationReadInDataBaseWithMessage:(ALMessage *)message {
    
    if (message.groupId != NULL) {
        [self.channelService setUnreadCountZeroForGroupID:message.groupId];
        ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
        [channelDBService markConversationAsRead:message.groupId];
    } else {
        [self setUnreadCountZeroForContactId:message.contactIds];
        [self.contactDBService markConversationAsDeliveredAndRead:message.contactIds];
        //  TODO: Mark message read&delivered in DB not whole conversation
    }
}

#pragma mark - Block user

- (void)blockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL hasUserBlocked))completion {
    if (userId.length == 0) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"Failed to block user where userId is empty" forKey:NSLocalizedDescriptionKey]];
        completion(error, NO);
        return;
    }
    [self.userClientService userBlockServerCall:userId withCompletion:^(NSString *jsonResponse, NSError *error) {
        
        if (!error) {

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to block user got response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, NO);
                return;
            }

            ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
                NSString *errorMessage = [response.errorResponse errorDescriptionMessage];
                NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                        userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"Failed to block user an api error occurred.": errorMessage
                                                                                             forKey:NSLocalizedDescriptionKey]];

                completion(reponseError, NO);
                return;
            }

            [self.contactDBService setBlockUser:userId andBlockedState:YES];
            completion(error, YES);
            return;
        }
        completion(error, NO);
    }];
}

#pragma mark - Block/Unblock sync

- (void)blockUserSync:(NSNumber *)lastSyncTime {
    [self.userClientService userBlockSyncServerCall:lastSyncTime withCompletion:^(NSString *jsonResponse, NSError *error) {
        
        if (!error) {
            ALUserBlockResponse *userBlockResponse = [[ALUserBlockResponse alloc] initWithJSONString:(NSString *)jsonResponse];
            [self updateBlockUserStatusToLocalDB:userBlockResponse];
            [ALUserDefaultsHandler setUserBlockLastTimeStamp:userBlockResponse.generatedAt];
        }
    }];
}

- (void)updateBlockUserStatusToLocalDB:(ALUserBlockResponse *)userBlockResponse {
    [self.contactDBService blockAllUserInList:userBlockResponse.blockedUserList];
    [self.contactDBService blockByUserInList:userBlockResponse.blockByUserList];
}

#pragma mark - Unblock user

- (void)unblockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL hasUserUnblocked))completion {
    
    if (userId.length == 0) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"Failed to unblock user where userId is empty" forKey:NSLocalizedDescriptionKey]];
        completion(error, NO);
        return;
    }
    
    [self.userClientService userUnblockServerCall:userId withCompletion:^(NSString *jsonResponse, NSError *error) {
        
        if (!error) {

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to unblock user got response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, NO);
                return;
            }

            ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
                NSString *errorMessage = [response.errorResponse errorDescriptionMessage];
                NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                        userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"Failed to unblock user an api error occurred.": errorMessage forKey:NSLocalizedDescriptionKey]];

                completion(reponseError, NO);
                return;
            }

            [self.contactDBService setBlockUser:userId andBlockedState:NO];
            completion(nil, YES);
            return;
        }
        completion(error, NO);
    }];
}

- (NSMutableArray *)getListOfBlockedUserByCurrentUser {
    NSMutableArray *blockedUsersList = [self.contactDBService getListOfBlockedUsers];
    return blockedUsersList;
}

#pragma mark - Fetch Registered contacts

- (void)getListOfRegisteredUsersWithCompletion:(void(^)(NSError *error))completion {
    NSNumber *startTime;
    if (![ALUserDefaultsHandler isContactServerCallIsDone]) {
        startTime = 0;
    } else {
        startTime = [ALApplozicSettings getStartTime];
    }
    NSUInteger pageSize = (NSUInteger)CONTACT_PAGE_SIZE;
    
    [self.userClientService getListOfRegisteredUsers:startTime andPageSize:pageSize withCompletion:^(ALContactsResponse *response, NSError *error) {
        
        if (error) {
            completion(error);
            return;
        }

        [ALApplozicSettings setStartTime:response.lastFetchTime];
        [self.contactDBService updateFilteredContacts:response withLoadContact:NO];
        completion(error);
        
    }];
    
}

#pragma mark - Fetch Online contacts

- (void)fetchOnlineContactFromServer:(void(^)(NSMutableArray *contactArray, NSError *error))completion {
    [self.userClientService fetchOnlineContactFromServer:[ALApplozicSettings getOnlineContactLimit] withCompletion:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSDictionary *JSONDictionary = (NSDictionary *)jsonResponse;
        NSMutableArray *contactArray = [NSMutableArray new];
        if (JSONDictionary.count) {
            ALUserDetail *userDetail = [ALUserDetail new];
            [userDetail parsingDictionaryFromJSON:JSONDictionary];
            NSString *paramString = userDetail.userIdString;
            
            [self.userClientService subProcessUserDetailServerCall:paramString withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                
                if (error) {
                    completion(nil, error);
                    return;
                }
                for (ALUserDetail *userDetail in userDetailArray) {
                    [self.contactDBService updateUserDetail: userDetail];
                    ALContact *contact = [self.contactDBService loadContactByKey:@"userId" value:userDetail.userId];
                    if (contact) {
                        [contactArray addObject:contact];
                    }
                }
                completion(contactArray, error);
            }];
        } else {
            completion(contactArray, nil);
        }
    }];
}

#pragma mark - Over all unread count (CHANNEL + CONTACTS)

- (NSNumber *)getTotalUnreadCount {
    NSNumber *contactUnreadCount = [self.contactService getOverallUnreadCountForContact];
    
    ALChannelService *channelService = [ALChannelService new];
    NSNumber *channelUnreadCount = [channelService getOverallUnreadCountForChannel];
    
    int totalCount = [contactUnreadCount intValue] + [channelUnreadCount intValue];
    NSNumber *unreadCount = [NSNumber numberWithInt:totalCount];
    
    return unreadCount;
}

- (void)resettingUnreadCountWithCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    [self.userClientService readCallResettingUnreadCountWithCompletion:^(NSString *jsonResponse, NSError *error) {
        
        completion(jsonResponse, error);
    }];
}

#pragma mark - Update user display, profile image or user status

- (void)updateUserDisplayName:(NSString *)displayName
                 andUserImage:(NSString *)imageLink
                   userStatus:(NSString *)status
               withCompletion:(void (^)(id jsonResponse, NSError *error))completion {
    
    if (!displayName && !imageLink && !status) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:[NSDictionary dictionaryWithObject:@"Failed to update login user details the parameters passed are nil"
                                                                                 forKey:NSLocalizedDescriptionKey]];
        completion(nil, nilError);
        return;
    }
    
    [self.userClientService updateUserDisplayName:displayName andUserImageLink:imageLink userStatus:status metadata: nil withCompletion:^(id jsonResponse, NSError *error) {
        completion(jsonResponse, error);
    }];
}

#pragma mark - Fetch Users Detail

- (void)getUserDetails:(NSMutableArray *)userArray withCompletion:(void (^)(NSMutableArray *userDetailArray, NSError *error))completion {
    
    ALUserDetailListFeed *userDetailListFeed = [ALUserDetailListFeed new];
    [userDetailListFeed setArray:userArray];
    
    [self.userClientService subProcessUserDetailServerCallPOST:userDetailListFeed withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
        
        if (userDetailArray && userDetailArray.count) {
            [self.contactDBService addUserDetailsWithoutUnreadCount:userDetailArray];
        }
        completion(userDetailArray, error);
    }];
}

#pragma mark - User Detail

- (void)getUserDetail:(NSString *)userId withCompletion:(void(^)(ALContact *contact))completion {
    
    if (!userId) {
        completion(nil);
        return;
    }
    
    if (![self.contactService isContactExist:userId]) {
        ALSLog(ALLoggerSeverityError, @"Contact not found fetching for user: %@", userId);
        [self getUserDetailFromServer:userId withCompletion:^(ALContact *contact, NSError *error) {

            if (error) {
                ALContact *newContact = [self.contactDBService loadContactByKey:@"userId" value:userId];
                completion(newContact);
                return;
            }
            completion(contact);
        }];
    } else {
        ALSLog(ALLoggerSeverityInfo, @"Contact is found for user: %@", userId);
        ALContact *contact = [self.contactDBService loadContactByKey:@"userId" value:userId];
        completion(contact);
    }
}

#pragma mark - Update user password

- (void)updatePassword:(NSString *)oldPassword
      withNewPassword :(NSString *)newPassword
        withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {
    
    if (!oldPassword || !newPassword) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic" code:1
                                            userInfo:[NSDictionary dictionaryWithObject:@"Failed to update old password or new password is nil"
                                                                                 forKey:NSLocalizedDescriptionKey]];
        completion(nil, nilError);
        return;
    }
    
    [self.userClientService updatePassword:oldPassword withNewPassword:newPassword withCompletion:^(ALAPIResponse *alAPIResponse, NSError *error) {


        if (error) {
            completion(nil, error);
            return;
        }

        if ([alAPIResponse.status isEqualToString:AL_RESPONSE_ERROR]) {
            NSString *errorMessage = [alAPIResponse.errorResponse errorDescriptionMessage];
            NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                    userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"Failed to change the user password an API error occurred.": errorMessage
                                                                                         forKey:NSLocalizedDescriptionKey]];



            completion(nil, reponseError);
            return;
        }
        [ALUserDefaultsHandler setPassword:newPassword];
        completion(alAPIResponse, error);
    }];
}

- (void)processResettingUnreadCount {
    ALUserService *userService = [ALUserService new];
    int count = [[userService getTotalUnreadCount] intValue];
    if (count == 0) {
        [userService resettingUnreadCountWithCompletion:^(NSString *jsonResponse, NSError *error) {
        }];
    }
}

#pragma mark - User or Contact search

- (void)getListOfUsersWithUserName:(NSString *)userName withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    
    if (!userName) {
        NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                userInfo:[NSDictionary dictionaryWithObject:@"Error search text is nil " forKey:NSLocalizedDescriptionKey]];
        completion(nil, reponseError);
        return;
    }
    
    [self.userClientService getListOfUsersWithUserName:userName withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        if (error) {
            completion(response, error);
            return;
        }

        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
            NSString *errorMessage = [response.errorResponse errorDescriptionMessage];
            NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                    userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"Failed to get users by name an API error occurred.": errorMessage
                                                                                         forKey:NSLocalizedDescriptionKey]];

            completion(nil, reponseError);
            return;
        }


        NSMutableArray *userDetailArray = (NSMutableArray*)response.response;
        for (NSDictionary *userDeatils in userDetailArray) {
            ALUserDetail *userDeatil = [[ALUserDetail alloc] initWithDictonary:userDeatils];
            userDeatil.unreadCount = 0;
            [self.contactDBService updateUserDetail:userDeatil];
        }
        completion(response, error);
    }];
}

- (void)updateConversationReadWithUserId:(NSString *)userId withDelegate:(id<ApplozicUpdatesDelegate>)delegate {
    
    [self setUnreadCountZeroForContactId:userId];
    if (delegate) {
        [delegate conversationReadByCurrentUser:userId withGroupId:nil];
    }
    NSDictionary *dict = @{@"userId":userId};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update_unread_count" object:dict];
}

#pragma mark - Muted user list.

- (void)getMutedUserListWithDelegate:(id<ApplozicUpdatesDelegate>)delegate
                      withCompletion:(void (^)(NSMutableArray *userDetailArray, NSError *error))completion {
    
    [self.userClientService getMutedUserListWithCompletion:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSArray *jsonArray = [NSArray arrayWithArray:(NSArray *)jsonResponse];
        NSMutableArray *userDetailArray = [NSMutableArray new];
        
        if (jsonArray.count) {
            NSDictionary *jsonDictionary = (NSDictionary *)jsonResponse;
            userDetailArray = [self.contactDBService addMuteUserDetailsWithDelegate:delegate withNSDictionary:jsonDictionary];
        }
        completion(userDetailArray, error);
    }];
}

#pragma mark - Mute or Unmute user.

- (void)muteUser:(ALMuteRequest *)muteRequest
  withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    
    if (!muteRequest.userId || muteRequest.notificationAfterTime == nil) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic" code:1
                                            userInfo:[NSDictionary dictionaryWithObject:@"Failed to mute user where userId or notificationAfterTime is nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, nilError);
        return;
    }
    
    [self.userClientService muteUser:muteRequest withCompletion:^(ALAPIResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {
            NSString *errorMessage = [response.errorResponse errorDescriptionMessage];
            NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                    userInfo:[NSDictionary dictionaryWithObject:errorMessage == nil ? @"Failed to mute user an api error occurred.": errorMessage forKey:NSLocalizedDescriptionKey]];

            completion(nil, reponseError);
            return;
        }

        ALUserDetail *userDetail = [self.contactService updateMuteAfterTime:muteRequest.notificationAfterTime andUserId:muteRequest.userId];
        [ALVerification verify:userDetail != nil withErrorMessage:@"Failed to update the mute time as user does not exist in database."];

        if (!userDetail) {
            NSError *updateUserDetailError = [NSError errorWithDomain:@"Applozic" code:1
                                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to mute user an error in saving in database." forKey:NSLocalizedDescriptionKey]];
            completion(nil, updateUserDetailError);
            return;
        }
        completion(response, error);
    }];
}

#pragma mark - Report user for message.

- (void)reportUserWithMessageKey:(NSString *)messageKey
                  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {
    
    if (messageKey.length == 0) {
        NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                userInfo:[NSDictionary dictionaryWithObject:@"Failed to report message the key is empty" forKey:NSLocalizedDescriptionKey]];
        completion(nil, reponseError);
        return;
    }
    
    [self.userClientService reportUserWithMessageKey:messageKey withCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
        completion(apiResponse, error);
    }];
}

- (void)disableChat:(BOOL)disable withCompletion:(void (^)(BOOL, NSError *))completion {
    ALContact *contact = [self.contactDBService loadContactByKey:@"userId" value:[ALUserDefaultsHandler getUserId]];
    if (!contact) {
        ALSLog(ALLoggerSeverityError, @"Contact details of logged-in user not present");
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"Contact not present" forKey:NSLocalizedDescriptionKey]];
        completion(NO, error);
        return;
    }
    NSMutableDictionary *metadata;
    if (contact != nil && contact.metadata != nil) {
        metadata = contact.metadata;
    } else {
        metadata = [[NSMutableDictionary alloc] init];
    }
    [metadata setObject:[NSNumber numberWithBool:disable] forKey: AL_DISABLE_USER_CHAT];
    ALUser *user = [[ALUser alloc] init];
    [user setMetadata: metadata];
    [self.userClientService updateUserDisplayName:nil andUserImageLink:nil userStatus:nil metadata:metadata withCompletion:^(id jsonResponse, NSError *error) {
        if (!error) {
            [self.contactDBService updateContactInDatabase: contact];
            [ALUserDefaultsHandler disableChat: disable];
            completion(YES, nil);
        } else {
            ALSLog(ALLoggerSeverityError, @"Error while disabling chat for user:%@",error);
            completion(NO, error);
        }
    }];
}

#pragma mark - Registered users/contacts in Application

- (void)getListOfRegisteredContactsWithNextPage:(BOOL)nextPage
                                 withCompletion:(void(^)(NSMutableArray *contactArray, NSError *error))completion {
    
    if (![ALUserDefaultsHandler isLoggedIn]) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"User is not logged in" forKey:NSLocalizedDescriptionKey]];
        completion(nil, error);
        return;
    }
    NSUInteger pageSize = (NSUInteger)CONTACT_PAGE_SIZE;
    NSNumber *startTime;
    if (nextPage) {
        startTime = [ALApplozicSettings getStartTime];
    } else {
        startTime = 0;
    }
    [self.userClientService getListOfRegisteredUsers:startTime
                                         andPageSize:pageSize
                                      withCompletion:^(ALContactsResponse *response, NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        }

        [ALVerification verify:response.userDetailList != nil withErrorMessage:@"Failed to get the registered users user Detail List response is nil"];

        if (!response.userDetailList) {
            NSError *apiError = [NSError
                                 errorWithDomain:@"Applozic"
                                 code:1
                                 userInfo:[NSDictionary dictionaryWithObject:@"Failed to get the registered users user detail list response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, apiError);
            return;
        }
        
        [ALApplozicSettings setStartTime:response.lastFetchTime];
        NSMutableArray *nextPageContactArray = [self.contactDBService updateFilteredContacts:response
                                                                             withLoadContact:nextPage];
        if (nextPage) {
            completion(nextPageContactArray, nil);
        } else {
            NSMutableArray *contcatArray = [self.contactDBService getAllContactsFromDB];
            completion(contcatArray, error);
        }
    }];
}

- (void)getUserDetailFromServer:(NSString *)userId
                 withCompletion:(void(^)(ALContact *contact, NSError *error))completion {

    if (userId.length == 0) {
        NSError *error = [NSError errorWithDomain:@"Applozic"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey : @"Passed UserId is empty"}];
        completion(nil, error);
        return;
    }

    ALUserDetailListFeed *userDetailListFeed = [[ALUserDetailListFeed alloc] init];
    NSMutableArray *userIdArray = [[NSMutableArray alloc] initWithObjects:userId, nil];
    [userDetailListFeed setArray:userIdArray];

    [self.userClientService subProcessUserDetailServerCallPOST:userDetailListFeed
                                                withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        if (userDetailArray.count == 0) {
            NSError *error = [NSError errorWithDomain:@"Applozic"
                                                 code:1
                                             userInfo:@{NSLocalizedDescriptionKey : @"User not found in Applozic"}];
            completion(nil, error);
            return;
        }

        [self.contactDBService addUserDetailsWithoutUnreadCount:userDetailArray];
        ALContact *contact = [self.contactDBService loadContactByKey:@"userId" value:userId];
        completion(contact, nil);
    }];
}

@end
