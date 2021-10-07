//
//  ALUserClientService.m
//  Applozic
//
//  Created by Devashish on 21/12/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALUserClientService.h"
#import <Foundation/Foundation.h>
#import "ALConstant.h"
#import "ALUserDefaultsHandler.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import "NSString+Encode.h"
#import "ALAPIResponse.h"
#import "ALUserDetailListFeed.h"
#import "ALLogger.h"

NSString * const ApplozicDomain = @"Applozic";

typedef NS_ENUM(NSInteger, ApplozicUserClientError) {
    MessageKeyNotPresent = 2
};

@implementation ALUserClientService

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
    self.responseHandler = [[ALResponseHandler alloc] init];
}

#pragma mark - Fetch last seen status of users

- (void)userLastSeenDetail:(NSNumber *)lastSeenAtTime
            withCompletion:(void(^)(ALLastSeenSyncFeed *))completionMark {
    NSString *userStatusURLString = [NSString stringWithFormat:@"%@/rest/ws/user/status",KBASE_URL];
    if (lastSeenAtTime == nil) {
        lastSeenAtTime = [ALUserDefaultsHandler getLastSyncTime];
        ALSLog(ALLoggerSeverityInfo, @"The lastSeenAt is coming as null seeting default vlaue to %@", lastSeenAtTime);
    }
    NSString *userStatusParamString = [NSString stringWithFormat:@"lastSeenAt=%@", lastSeenAtTime];
    ALSLog(ALLoggerSeverityInfo, @"Calling last seen at api with %@", userStatusParamString);
    
    NSMutableURLRequest *userStatusRequest = [ALRequestHandler createGETRequestWithUrlString:userStatusURLString paramString:userStatusParamString];
    [self.responseHandler authenticateAndProcessRequest:userStatusRequest
                                                 andTag:@"USER_LAST_SEEN_NEW"
                                  WithCompletionHandler:^(id theJson, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in last seen fetching: %@", error);
            completionMark(nil);
            return;
        } else {
            NSNumber *generatedAt = [theJson valueForKey:@"generatedAt"];
            [ALUserDefaultsHandler setLastSeenSyncTime:generatedAt];
            ALLastSeenSyncFeed *responseFeed = [[ALLastSeenSyncFeed alloc] initWithJSONString:(NSString*)theJson];
            completionMark(responseFeed);
        }
    }];
}

#pragma mark - User Detail

- (void)userDetailServerCall:(NSString *)userId
              withCompletion:(void(^)(ALUserDetail *))completionMark {
    NSString *userDetailURLString = [NSString stringWithFormat:@"%@/rest/ws/user/detail",KBASE_URL];
    NSString *userDetailParamString = [NSString stringWithFormat:@"userIds=%@",[userId urlEncodeUsingNSUTF8StringEncoding]];
    
    ALSLog(ALLoggerSeverityInfo, @"Callig user detail API for the userId: %@", userId);
    NSMutableURLRequest *userDetailRequest = [ALRequestHandler createGETRequestWithUrlString:userDetailURLString paramString:userDetailParamString];
    
    [self.responseHandler authenticateAndProcessRequest:userDetailRequest andTag:@"USER_LAST_SEEN" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error while fetching user detail : %@", error);
            completionMark(nil);
            return;
        }
        
        if (((NSArray *)jsonResponse).count > 0) {
            ALSLog(ALLoggerSeverityInfo, @"User detail response JSON : %@", (NSString *)jsonResponse);
            ALUserDetail *userDetailObject = [[ALUserDetail alloc] initWithDictonary:[jsonResponse objectAtIndex:0]];
            completionMark(userDetailObject);
        } else {
            completionMark(nil);
        }
    }];
}

#pragma mark - Update user display, profile image or user status

- (void)updateUserDisplayName:(ALContact *)contact
               withCompletion:(void(^)(id jsonResponse, NSError *error))completion {
    NSString *updateDisplayNameURLString = [NSString stringWithFormat:@"%@/rest/ws/user/name", KBASE_URL];
    NSString *updateDisplayNameParamString = [NSString stringWithFormat:@"userId=%@&displayName=%@",
                                              [contact.userId urlEncodeUsingNSUTF8StringEncoding],
                                              [contact.displayName urlEncodeUsingNSUTF8StringEncoding]];
    
    NSMutableURLRequest *updateDisplayNameRequest = [ALRequestHandler createGETRequestWithUrlString:updateDisplayNameURLString
                                                                                        paramString:updateDisplayNameParamString];
    [self.responseHandler authenticateAndProcessRequest:updateDisplayNameRequest
                                                 andTag:@"USER_DISPLAY_NAME_UPDATE"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        } else {
            ALSLog(ALLoggerSeverityInfo, @"Response of USER_DISPLAY_NAME_UPDATE : %@", (NSString *)jsonResponse);
            completion((NSString *)jsonResponse, nil);
        }
    }];
    
}

#pragma mark - Mark Conversation as read

- (void)markConversationAsReadforContact:(NSString *)userId
                          withCompletion:(void (^)(NSString *, NSError *))completion {
    
    NSString *conversationReadURL = [NSString stringWithFormat:@"%@/rest/ws/message/read/conversation",KBASE_URL];
    NSString *conversationReadParamString = [NSString stringWithFormat:@"userId=%@",[userId urlEncodeUsingNSUTF8StringEncoding]];
    NSMutableURLRequest *conversationReadRequest = [ALRequestHandler createGETRequestWithUrlString:conversationReadURL paramString:conversationReadParamString];
    [self.responseHandler authenticateAndProcessRequest:conversationReadRequest
                                                 andTag:@"MARK_CONVERSATION_AS_READ"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Response for mark conversation: %@", (NSString *)jsonResponse);
        completion((NSString *)jsonResponse, nil);
    }];
}

#pragma mark - Block user

- (void)userBlockServerCall:(NSString *)userId
             withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    NSString *userBlockURLString = [NSString stringWithFormat:@"%@/rest/ws/user/block",KBASE_URL];
    NSString *userBlockParamString = [NSString stringWithFormat:@"userId=%@",[userId urlEncodeUsingNSUTF8StringEncoding]];
    
    NSMutableURLRequest *userBlockRequest = [ALRequestHandler createGETRequestWithUrlString:userBlockURLString paramString:userBlockParamString];
    
    [self.responseHandler authenticateAndProcessRequest:userBlockRequest andTag:@"USER_BLOCKED" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"User block got some error: %@",error);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"USER_BLOCKED RESPONSE JSON: %@", (NSString *)jsonResponse);
        completion((NSString *)jsonResponse, nil);
    }];
    
}

#pragma mark - Block/Unblock sync

- (void)userBlockSyncServerCall:(NSNumber *)lastSyncTime
                 withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    NSString *userBlockSyncURLString = [NSString stringWithFormat:@"%@/rest/ws/user/blocked/sync",KBASE_URL];
    NSString *userBlockSyncParamString = [NSString stringWithFormat:@"lastSyncTime=%@",lastSyncTime];
    
    NSMutableURLRequest *userBlockSyncRequest = [ALRequestHandler createGETRequestWithUrlString:userBlockSyncURLString paramString:userBlockSyncParamString];
    
    [self.responseHandler authenticateAndProcessRequest:userBlockSyncRequest
                                                 andTag:@"USER_BLOCK_SYNC"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"User block sync error : %@",error.localizedDescription);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"USER_BLOCKED SYNC RESPONSE JSON: %@", (NSString *)jsonResponse);
        completion((NSString *)jsonResponse, nil);
    }];
}

#pragma mark - Unblock user

- (void)userUnblockServerCall:(NSString *)userId
               withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    NSString *userUnblockURLString = [NSString stringWithFormat:@"%@/rest/ws/user/unblock",KBASE_URL];
    NSString *userUnblockParamString = [NSString stringWithFormat:@"userId=%@",[userId urlEncodeUsingNSUTF8StringEncoding]];
    
    NSMutableURLRequest *userUnblockRequest = [ALRequestHandler createGETRequestWithUrlString:userUnblockURLString paramString:userUnblockParamString];
    [self.responseHandler authenticateAndProcessRequest:userUnblockRequest
                                                 andTag:@"USER_UNBLOCKED"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"User unblock error : %@",error.localizedDescription);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Response USER_UNBLOCKED:%@",(NSString *)jsonResponse);
        completion((NSString *)jsonResponse, nil);
    }];
}

#pragma mark - Mark message as read

- (void)markMessageAsReadforPairedMessageKey:(NSString *)pairedMessageKey
                              withCompletion:(void (^)(NSString *, NSError *))completion {
    
    NSString *messageReadURLString = [NSString stringWithFormat:@"%@/rest/ws/message/read",KBASE_URL];
    NSString *messageReadParamString = [NSString stringWithFormat:@"key=%@",pairedMessageKey];
    
    NSMutableURLRequest *messageReadRequest = [ALRequestHandler createGETRequestWithUrlString:messageReadURLString paramString:messageReadParamString];
    
    [self.responseHandler authenticateAndProcessRequest:messageReadRequest andTag:@"MARK_MESSAGE_AS_READ" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in marking a message as read: %@", error.localizedDescription);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Response of mark message as read: %@",jsonResponse);
        completion((NSString *)jsonResponse, nil);
    }];
}

#pragma mark - Multi User Send Message

- (void)multiUserSendMessage:(NSDictionary *)messageDictionary
                  toContacts:(NSMutableArray *)contactIdsArray
                    toGroups:(NSMutableArray *)channelKeysArray
              withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    
    NSString *sendAllURLString = [NSString stringWithFormat:@"%@/rest/ws/message/sendall",KBASE_URL];
    
    NSMutableDictionary *channelDictionary = [NSMutableDictionary new];
    [channelDictionary setObject:contactIdsArray forKey:@"userNames"];
    [channelDictionary setObject:channelKeysArray forKey:@"groupIds"];
    [channelDictionary setObject:messageDictionary forKey:@"messageObject"];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:channelDictionary options:0 error:&error];
    NSString *sendAllParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    NSMutableURLRequest *messageToAllRequest =  [ALRequestHandler createPOSTRequestWithUrlString:sendAllURLString paramString:sendAllParamString];
    
    [self.responseHandler authenticateAndProcessRequest:messageToAllRequest andTag:@"MULTI_USER_SEND" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        completion(jsonResponse, error);
    }];
}

#pragma mark - Fetch Registered contacts

- (void)getListOfRegisteredUsers:(NSNumber *)startTime
                     andPageSize:(NSUInteger)pageSize
                  withCompletion:(void(^)(ALContactsResponse *response, NSError *error))completion {
    NSString *registeredUserURLString = [NSString stringWithFormat:@"%@/rest/ws/user/filter",KBASE_URL];
    NSString *pageSizeString = [NSString stringWithFormat:@"%lu", (unsigned long)pageSize];
    
    NSString *registeredUserParamString = @"";
    registeredUserParamString = [NSString stringWithFormat:@"pageSize=%@", pageSizeString];
    if (startTime != nil) {
        registeredUserParamString = [NSString stringWithFormat:@"pageSize=%@&startTime=%@", pageSizeString, startTime];
    }
    
    NSMutableURLRequest *registeredUserRequest = [ALRequestHandler createGETRequestWithUrlString:registeredUserURLString paramString:registeredUserParamString];
    
    [self.responseHandler authenticateAndProcessRequest:registeredUserRequest andTag:@"FETCH_REGISTERED_CONTACT_WITH_PAGE_SIZE" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            ALSLog(ALLoggerSeverityError, @"ERROR_IN_FETCH_CONTACT_WITH_PAGE_SIZE : %@", error);
            return;
        }
        
        NSString *responseJSONString = (NSString *)jsonResponse;
        if ([responseJSONString isKindOfClass:[NSString class]] &&
            [responseJSONString isEqualToString:AL_RESPONSE_ERROR]) {
            NSError *error = [NSError
                              errorWithDomain:@"Applozic"
                              code:1
                              userInfo:[NSDictionary dictionaryWithObject:@"Got some error failed to fetch the registered contacts" forKey:NSLocalizedDescriptionKey]];
            completion(nil, error);
            return;
        }
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REGISTERED_CONTACT_WITH_PAGE_SIZE_JSON : %@", responseJSONString);
        ALContactsResponse *contactResponse = [[ALContactsResponse alloc] initWithJSONString:responseJSONString];
        [ALUserDefaultsHandler setContactViewLoadStatus:YES];
        completion(contactResponse, nil);
    }];
}

#pragma mark - Fetch Online contacts

- (void)fetchOnlineContactFromServer:(NSUInteger)limit
                      withCompletion:(void (^)(id jsonResponse, NSError *error))completion {
    NSString *onlineUserURLString = [NSString stringWithFormat:@"%@/rest/ws/user/ol/list",KBASE_URL];
    NSString *onlineUserParamString = [NSString stringWithFormat:@"startIndex=0&pageSize=%lu",(unsigned long)limit];
    
    NSMutableURLRequest *onlineUserRequest = [ALRequestHandler createGETRequestWithUrlString:onlineUserURLString paramString:onlineUserParamString];
    
    [self.responseHandler authenticateAndProcessRequest:onlineUserRequest andTag:@"CONTACT_FETCH_WITH_LIMIT" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            ALSLog(ALLoggerSeverityError, @"ERROR_IN_CONTACT_FETCH_WITH_LIMIT : %@",error);
            return;
        }
        
        NSString *JSONString = (NSString *)jsonResponse;
        ALSLog(ALLoggerSeverityInfo, @"SERVER_RESPONSE_CONTACT_FETCH_WITH_LIMIT_JSON : %@", JSONString);
        completion(jsonResponse, error);
    }];
}

- (void)subProcessUserDetailServerCall:(NSString *)paramString
                        withCompletion:(void(^)(NSMutableArray *userDetailArray, NSError *error))completionMark {
    
    @try {
        NSString *userDetailURLString = [NSString stringWithFormat:@"%@/rest/ws/user/detail",KBASE_URL];
        NSMutableURLRequest *userDetailRequest = [ALRequestHandler createGETRequestWithUrlString:userDetailURLString paramString:paramString];
        
        [self.responseHandler authenticateAndProcessRequest:userDetailRequest
                                                     andTag:@"USERS_DETAILS_FOR_ONLINE_CONTACT_LIMIT"
                                      WithCompletionHandler:^(id jsonResponse, NSError *error) {
            
            if (error) {
                completionMark(nil, error);
                ALSLog(ALLoggerSeverityError, @"ERROR_IN_USERS_DETAILS_FOR_ONLINE_CONTACT_LIMIT : %@", error);
                return;
            }
            
            ALSLog(ALLoggerSeverityInfo, @"SERVER_RESPONSE_FOR_ONLINE_CONTACT_LIMIT_JSON : %@", (NSString *)jsonResponse);
            NSArray *jsonArray = [NSArray arrayWithArray:(NSArray *)jsonResponse];
            if (jsonArray.count) {
                NSMutableArray *userDetailArray = [NSMutableArray new];
                NSDictionary *JSONDictionary = (NSDictionary *)jsonResponse;
                for (NSDictionary *theDictionary in JSONDictionary) {
                    ALUserDetail *userDetail = [[ALUserDetail alloc] initWithDictonary:theDictionary];
                    userDetail.unreadCount = 0;
                    [userDetailArray addObject:userDetail];
                }
                completionMark(userDetailArray, error);
            } else {
                NSError *error = [NSError
                                  errorWithDomain:@"Applozic"
                                  code:1
                                  userInfo:[NSDictionary dictionaryWithObject:@"Failed to fetch user detail" forKey:NSLocalizedDescriptionKey]];
                completionMark(nil, error);
            }
        }];
    } @catch(NSException *exp) {
        ALSLog(ALLoggerSeverityError, @"EXCEPTION : UserDetail :: %@",exp.description);
        
    }
}

# pragma mark - Call for resetting unread count

- (void)readCallResettingUnreadCountWithCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    NSString *resetUnreadCountURLString = [NSString stringWithFormat:@"%@/rest/ws/user/read",KBASE_URL];
    NSMutableURLRequest *resetUnreadCountRequest = [ALRequestHandler createGETRequestWithUrlString:resetUnreadCountURLString paramString:nil];
    
    [self.responseHandler authenticateAndProcessRequest:resetUnreadCountRequest
                                                 andTag:@"RESETTING_UNREAD_COUNT"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE RESETTING_UNREAD_COUNT :: %@",(NSString *)jsonResponse);
        if (error) {
            completion(nil, error);
            ALSLog(ALLoggerSeverityError, @"ERROR : RESETTING UNREAD COUNT :: %@",error.description);
            return;
        }
        completion((NSString *)jsonResponse, nil);
    }];
    
}

#pragma mark - Update user display name/Status/Profile Image

- (void)updateUserDisplayName:(NSString *)displayName
             andUserImageLink:(NSString *)imageLink
                   userStatus:(NSString *)status
                     metadata:(NSMutableDictionary *)metadata
               withCompletion:(void (^)(id jsonResponse, NSError *error))completionHandler {
    
    NSString *userUpdateURLString = [NSString stringWithFormat:@"%@/rest/ws/user/update",KBASE_URL];
    
    NSMutableDictionary *userUpdateDictionary = [NSMutableDictionary new];
    if (displayName) {
        [userUpdateDictionary setObject:displayName forKey:@"displayName"];
    }
    if (imageLink) {
        [userUpdateDictionary setObject:imageLink forKey:@"imageLink"];
    }
    if (status) {
        [userUpdateDictionary setObject:status forKey:@"statusMessage"];
    }
    if (metadata) {
        [userUpdateDictionary setObject:metadata forKey:@"metadata"];
    }
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:userUpdateDictionary options:0 error:&error];
    NSString *userUpdateParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    
    NSMutableURLRequest *userUpdateRequest = [ALRequestHandler createPOSTRequestWithUrlString:userUpdateURLString paramString:userUpdateParamString];
    
    [self.responseHandler authenticateAndProcessRequest:userUpdateRequest
                                                 andTag:@"UPDATE_DISPLAY_NAME_AND_PROFILE_IMAGE"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        ALSLog(ALLoggerSeverityInfo, @"UPDATE_USER_DISPLAY_NAME/PROFILE_IMAGE/USER_STATUS :: %@",(NSString *)jsonResponse);
        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)jsonResponse];
        if ([apiResponse.status isEqualToString:AL_RESPONSE_ERROR]) {
            NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                    userInfo:[NSDictionary dictionaryWithObject:@"ERROR IN JSON STATUS WHILE UPDATING USER STATUS"
                                                                                         forKey:NSLocalizedDescriptionKey]];
            completionHandler(jsonResponse, reponseError);
            return;
        }
        completionHandler(jsonResponse, error);
    }];
}

#pragma mark - Update phone number, email of user with admin user

- (void)updateUser:(NSString *)phoneNumber
             email:(NSString *)email
            ofUser:(NSString *)userId
    withCompletion:(void (^)(id, NSError *))completion {
    NSString *userUpdateURLString = [NSString stringWithFormat:@"%@/rest/ws/user/update", KBASE_URL];
    NSMutableDictionary *userUpdateDictionary = [NSMutableDictionary new];
    if (phoneNumber) {
        [userUpdateDictionary setObject:phoneNumber forKey:@"phoneNumber"];
    }
    if (email) {
        [userUpdateDictionary setObject:email forKey:@"email"];
    }
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:userUpdateDictionary options:0 error:&error];
    NSString *userUpdateParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    
    NSMutableURLRequest *userUpdateRequest = [ALRequestHandler createPOSTRequestWithUrlString:userUpdateURLString
                                                                                  paramString:userUpdateParamString
                                                                                     ofUserId:userId];
    
    [self.responseHandler authenticateAndProcessRequest:userUpdateRequest andTag:@"UPDATE_PHONE_AND_EMAIL" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        ALSLog(ALLoggerSeverityInfo, @"Update user phone/email :: %@",(NSString *)jsonResponse);
        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)jsonResponse];
        if ([apiResponse.status isEqualToString:AL_RESPONSE_ERROR]) {
            NSError *reponseError =
            [NSError errorWithDomain:@"Applozic"
                                code:1
                            userInfo: [NSDictionary
                                       dictionaryWithObject:@"Error in updating user"
                                       forKey:NSLocalizedDescriptionKey]];
            completion(nil, reponseError);
            return;
        }
        completion(apiResponse.response, error);
    }];
}

#pragma mark - Fetch Users Detail

- (void)subProcessUserDetailServerCallPOST:(ALUserDetailListFeed *)ob
                            withCompletion:(void(^)(NSMutableArray *userDetailArray, NSError *error))completionMark {
    NSString *theUrlString = [NSString stringWithFormat:@"%@/rest/ws/user/v2/detail",KBASE_URL];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:ob.dictionary options:0 error:&error];
    NSString *userDetailParamString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    ALSLog(ALLoggerSeverityInfo, @"PARAM_POST_CALL : %@",userDetailParamString);
    
    NSMutableURLRequest *userDetailRequest = [ALRequestHandler createPOSTRequestWithUrlString:theUrlString paramString:userDetailParamString];
    [self.responseHandler authenticateAndProcessRequest:userDetailRequest
                                                 andTag:@"USERS_DETAILS_POST"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completionMark(nil, error);
            return;
        }
        
        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)jsonResponse];
        NSMutableArray *userDetailArray = [NSMutableArray new];
        if ([apiResponse.status isEqualToString:AL_RESPONSE_SUCCESS]) {
            NSDictionary *JSONDictionary = (NSDictionary *)apiResponse.response;
            for (NSDictionary *theDictionary in JSONDictionary) {
                ALUserDetail *userDetail = [[ALUserDetail alloc] initWithDictonary:theDictionary];
                [userDetailArray addObject:userDetail];
            }
            completionMark(userDetailArray, nil);
        } else {
            NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                    userInfo:[NSDictionary dictionaryWithObject:@"ERROR IN JSON STATUS WHILE FETCHING USER DETAILS"
                                                                                         forKey:NSLocalizedDescriptionKey]];
            completionMark(nil, reponseError);
        }
    }];
}

#pragma mark - Update user password

- (void)updatePassword:(NSString *)oldPassword
       withNewPassword:(NSString *)newPassword
        withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {
    
    NSString *passwordUpdateURLString = [NSString stringWithFormat:@"%@/rest/ws/user/update/password", KBASE_URL];
    NSString *passwordUpdateParamString = [NSString stringWithFormat:@"oldPassword=%@&newPassword=%@", oldPassword,
                                           newPassword];
    
    NSMutableURLRequest *passwordUpdateRequest = [ALRequestHandler createGETRequestWithUrlString:passwordUpdateURLString paramString:passwordUpdateParamString];
    [self.responseHandler authenticateAndProcessRequest:passwordUpdateRequest
                                                 andTag:@"UPDATE_USER_PASSWORD"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        ALAPIResponse *apiResponse = nil;
        if (!error){
            apiResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)jsonResponse];
        }
        completion(apiResponse, error);
    }];
}

#pragma mark - User or Contact search

- (void)getListOfUsersWithUserName:(NSString *)userName
                    withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    NSString *searchContactURLString = [NSString stringWithFormat:@"%@/rest/ws/user/search/contact",KBASE_URL];
    
    NSString *searchContactParamString = [NSString stringWithFormat:@"name=%@", [userName urlEncodeUsingNSUTF8StringEncoding]];
    
    NSMutableURLRequest *searchContactRequest = [ALRequestHandler createGETRequestWithUrlString:searchContactURLString paramString:searchContactParamString];
    
    [self.responseHandler authenticateAndProcessRequest:searchContactRequest
                                                 andTag:@"FETCH_LIST_OF_USERS_WITH_NAME"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            ALSLog(ALLoggerSeverityError, @"Error in list of users api call : %@", error);
            return;
        }
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_FETCH_LIST_OF_USERS_WITH_NAME_JSON : %@",(NSString *)jsonResponse);
        
        ALAPIResponse *alAPIResponse = [[ALAPIResponse alloc] initWithJSONString:(NSString *)jsonResponse];
        completion(alAPIResponse, error);
    }];
}

#pragma mark - Muted user list.

- (void)getMutedUserListWithCompletion:(void(^)(id jsonResponse, NSError *error))completion {
    NSString *mutedUserURLString = [NSString stringWithFormat:@"%@/rest/ws/user/chat/mute/list",KBASE_URL];
    
    NSMutableURLRequest *mutedUserRequest = [ALRequestHandler createGETRequestWithUrlString:mutedUserURLString paramString:nil];
    [self.responseHandler authenticateAndProcessRequest:mutedUserRequest
                                                 andTag:@"FETCH_MUTED_USER_LIST"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            ALSLog(ALLoggerSeverityError, @"Error in mute user list api  call : %@", error);
            return;
        }
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_FETCH_MUTED_USER_LIST : %@",(NSString *)jsonResponse);
        
        completion(jsonResponse, error);
    }];
}

#pragma mark - Mute or Unmute user.

- (void)muteUser:(ALMuteRequest *)alMuteRequest
  withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    
    NSString *muteURLString = [NSString stringWithFormat:@"%@/rest/ws/user/chat/mute?userId=%@&notificationAfterTime=%@",KBASE_URL,[alMuteRequest.userId urlEncodeUsingNSUTF8StringEncoding],alMuteRequest.notificationAfterTime];
    
    NSMutableURLRequest *muteUserRequest = [ALRequestHandler createPOSTRequestWithUrlString:muteURLString paramString:nil];
    
    [self.responseHandler authenticateAndProcessRequest:muteUserRequest andTag:@"MUTE_USER" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in mute user : %@", error);
            completion(nil, error);
            return;
        }
        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        completion(response, nil);
    }];
}

#pragma mark - Report user for message

- (void)reportUserWithMessageKey:(NSString *)messageKey
                  withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {
    
    if (messageKey == nil) {
        NSError *error =  [NSError errorWithDomain:ApplozicDomain
                                              code:MessageKeyNotPresent
                                          userInfo:@{NSLocalizedDescriptionKey : @"Message key is nil"}];
        completion(nil,error);
        return;
    }
    
    NSString *reportMessageURLString = [NSString stringWithFormat:@"%@/rest/ws/message/report?messageKey=%@", KBASE_URL, messageKey];
    
    NSMutableURLRequest *reportMessageRequest = [ALRequestHandler createPOSTRequestWithUrlString:reportMessageURLString paramString:nil];
    
    [self.responseHandler authenticateAndProcessRequest:reportMessageRequest
                                                 andTag:@"REPORT_USER"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {
        if (error){
            ALSLog(ALLoggerSeverityError, @"Error in reporting  user : %@", error);
            completion(nil, error);
            return;
        }
        
        NSString *responseString = (NSString *)jsonResponse;
        
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REPORT_USER : %@",responseString);
        
        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:responseString];
        
        if (![apiResponse.status isEqualToString:AL_RESPONSE_SUCCESS]) {
            NSError *error = [NSError errorWithDomain:ApplozicDomain
                                                 code:MessageKeyNotPresent
                                             userInfo:@{NSLocalizedDescriptionKey : @"Failed to report message api error occurred"}];
            completion(nil, error);
            return;
        }
        completion(apiResponse, error);
    }];
}

@end
