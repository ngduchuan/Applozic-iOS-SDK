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

-(void)setupServices {
    self.userClientService = [[ALUserClientService alloc] init];
    self.channelService = [[ALChannelService alloc] init];
    self.contactDBService = [[ALContactDBService alloc] init];
    self.contactService = [[ALContactService alloc] init];
}

#pragma mark - Fetch users from messages

- (void)processContactFromMessages:(NSArray *)messages withCompletion:(void(^)(void))completionMark {
    
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
    [self fetchAndupdateUserDetails:userIdArray withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
        if(error || !userDetailArray){
            completionMark();
            return;
        }
        completionMark();
    }];
}

#pragma mark - Fetch last seen status of users

- (void)getLastSeenUpdateForUsers:(NSNumber *)lastSeenAtTime withCompletion:(void(^)(NSMutableArray *))completionMark {
    
    [self.userClientService userLastSeenDetail:lastSeenAtTime withCompletion:^(ALLastSeenSyncFeed *lastSeenSyncFeed) {
        NSMutableArray *lastSeenUpdateArray = lastSeenSyncFeed.lastSeenArray;
        for (ALUserDetail *userDetail in lastSeenUpdateArray){
            userDetail.unreadCount = 0;
            [self.contactDBService updateUserDetail:userDetail];
        }
        completionMark(lastSeenUpdateArray);
    }];
}

- (void)userDetailServerCall:(NSString *)userId withCompletion:(void(^)(ALUserDetail *))completionMark {
    
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
    [self userDetailServerCall:userId withCompletion:^(ALUserDetail *userDetail) {
        
        if (userDetail) {
            userDetail.unreadCount = 0;
            [self.contactDBService updateUserDetail:userDetail];
        }
        completionMark(userDetail);
    }];
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
            [self.contactDBService updateContactInDatabase:contact];
            completion(YES);
            return;
        }
        completion(NO);
    }];
}

- (void)updateUserDisplayName:(ALContact *)contact {
    if (contact.userId && contact.displayName) {
        [self.userClientService updateUserDisplayName:contact withCompletion:^(id jsonResponse, NSError *error) {
            
            if (jsonResponse) {
                ALSLog(ALLoggerSeverityError, @"GETTING ERROR in SEVER CALL FOR DISPLAY NAME");
            } else {
                ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
                ALSLog(ALLoggerSeverityInfo, @"RESPONSE_STATUS :: %@", apiResponse.status);
            }
        }];
    } else {
        return;
    }
}

#pragma mark - Update display name user who is not registered

- (void)updateDisplayNameWith:(NSString *)userId
              withDisplayName:(NSString *)displayName
               withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error)) completion {
    
    if (!userId || !displayName) {
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

- (void)markConversationAsRead:(NSString *)userId withCompletion:(void (^)(NSString *, NSError *))completion {
    
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
        return;
    }
    [self.userClientService markConversationAsReadforContact:userId withCompletion:^(NSString *response, NSError *error){
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
    
    if (!pairedkeyValue) {
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
        ALSLog(ALLoggerSeverityInfo, @"Response Marking Message :%@",response);
        
        if (error) {
            completion(nil, error);
            return;
        }
        
        if ([response isEqualToString:AL_RESPONSE_SUCCESS]) {
            completion(response, nil);
        } else {
            NSError *apiError = [NSError
                                 errorWithDomain:@"Applozic"
                                 code:1
                                 userInfo:[NSDictionary dictionaryWithObject:@"Failed to mark message as read api error occurred" forKey:NSLocalizedDescriptionKey]];
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

- (void)blockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL userBlock))completion {
    if (!userId) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"Failed to block user where userId is nil" forKey:NSLocalizedDescriptionKey]];
        completion(error, NO);
        return;
    }
    [self.userClientService userBlockServerCall:userId withCompletion:^(NSString *jsonResponse, NSError *error) {
        
        if (!error) {
            ALAPIResponse *forBlockUserResponse = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
            if ([forBlockUserResponse.status isEqualToString:AL_RESPONSE_SUCCESS]) {
                [self.contactDBService setBlockUser:userId andBlockedState:YES];
                completion(error, YES);
                return;
            } else {
                NSError *apiError = [NSError
                                     errorWithDomain:@"Applozic"
                                     code:1
                                     userInfo:[NSDictionary dictionaryWithObject:@"Failed to block user api error occurred" forKey:NSLocalizedDescriptionKey]];
                completion(apiError, NO);
                return;
            }
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

- (void)unblockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL userUnblock))completion {
    
    if (!userId) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"Failed to unblock user where userId is nil" forKey:NSLocalizedDescriptionKey]];
        completion(error, NO);
        return;
    }
    
    [self.userClientService userUnblockServerCall:userId withCompletion:^(NSString *jsonResponse, NSError *error) {
        
        if (!error) {
            ALAPIResponse *forBlockUserResponse = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
            if ([forBlockUserResponse.status isEqualToString:AL_RESPONSE_SUCCESS]) {
                [self.contactDBService setBlockUser:userId andBlockedState:NO];
                completion(error, YES);
                return;
            } else {
                NSError *apiError = [NSError
                                     errorWithDomain:@"Applozic"
                                     code:1
                                     userInfo:[NSDictionary dictionaryWithObject:@"Failed to unblock user api error occurred" forKey:NSLocalizedDescriptionKey]];
                completion(apiError, NO);
                return;
            }
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

- (void)fetchOnlineContactFromServer:(void(^)(NSMutableArray *array, NSError *error))completion {
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
                    [contactArray addObject:contact];
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
        NSError *nilError = [NSError errorWithDomain:@"Applozic" code:1
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

- (void)fetchAndupdateUserDetails:(NSMutableArray *)userArray withCompletion:(void (^)(NSMutableArray *userDetailArray, NSError *error))completion {
    
    ALUserDetailListFeed *userDetailListFeed = [ALUserDetailListFeed new];
    [userDetailListFeed setArray:userArray];
    
    [self.userClientService subProcessUserDetailServerCallPOST:userDetailListFeed withCompletion:^(NSMutableArray *userDetailArray, NSError *theError) {
        
        if (userDetailArray && userDetailArray.count) {
            [self.contactDBService addUserDetailsWithoutUnreadCount:userDetailArray];
        }
        completion(userDetailArray, theError);
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
        
        [self userDetailServerCall:userId withCompletion:^(ALUserDetail *alUserDetail) {
            [self.contactDBService updateUserDetail:alUserDetail];
            ALContact *contact = [self.contactDBService loadContactByKey:@"userId" value:userId];
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
    
    [self.userClientService updatePassword:oldPassword withNewPassword:newPassword withCompletion:^(ALAPIResponse *alAPIResponse, NSError *theError) {
        
        if (!theError) {
            if ([alAPIResponse.status isEqualToString:AL_RESPONSE_ERROR]) {
                NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                        userInfo:[NSDictionary dictionaryWithObject:@"ERROR IN UPDATING PASSWORD"
                                                                                             forKey:NSLocalizedDescriptionKey]];
                completion(alAPIResponse, reponseError);
                return;
            }
            [ALUserDefaultsHandler setPassword:newPassword];
        }
        completion(alAPIResponse, theError);
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
                                                userInfo:[NSDictionary dictionaryWithObject:@"Error userName is nil " forKey:NSLocalizedDescriptionKey]];
        completion(nil, reponseError);
        return;
    }
    
    [self.userClientService getListOfUsersWithUserName:userName withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        if (error) {
            completion(response, error);
            return;
        }
        if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
            
            NSMutableArray *userDetailArray = (NSMutableArray*)response.response;
            for (NSDictionary *userDeatils in userDetailArray) {
                ALUserDetail *userDeatil = [[ALUserDetail alloc] initWithDictonary:userDeatils];
                userDeatil.unreadCount = 0;
                [self.contactDBService updateUserDetail:userDeatil];
            }
            completion(response, error);
            return;
        }
        NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                userInfo:[NSDictionary dictionaryWithObject:@"Failed to fetch users due to api error occurred" forKey:NSLocalizedDescriptionKey]];
        
        completion(nil, reponseError);
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
                      withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    
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
    
    if (!muteRequest) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic" code:1
                                            userInfo:[NSDictionary dictionaryWithObject:@"Failed to mute user ALMuteRequest is nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, nilError);
        return;
    }
    
    
    if (!muteRequest.userId || !muteRequest.notificationAfterTime) {
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
        
        if (response && [response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
            [self.contactService updateMuteAfterTime:muteRequest.notificationAfterTime andUserId:muteRequest.userId];
            completion(response, error);
            return;
        }
        
        NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                userInfo:[NSDictionary dictionaryWithObject:@"Failed to mute user api error occurred" forKey:NSLocalizedDescriptionKey]];
        completion(nil, reponseError);
    }];
}

#pragma mark - Report user for message.

- (void)reportUserWithMessageKey:(NSString *)messageKey
                  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {
    
    if (!messageKey) {
        NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                userInfo:[NSDictionary dictionaryWithObject:@"Failed to report message the key is nil" forKey:NSLocalizedDescriptionKey]];
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
            ALSLog(ALLoggerSeverityError, @"Error while disabling chat for user");
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

@end
