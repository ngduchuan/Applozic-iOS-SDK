//
//  ALUserClientService.h
//  Applozic
//
//  Created by Devashish on 21/12/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import "ALContact.h"
#import "ALContactsResponse.h"
#import "ALLastSeenSyncFeed.h"
#import "ALMuteRequest.h"
#import "ALResponseHandler.h"
#import "ALUserDetailListFeed.h"
#import <Foundation/Foundation.h>

@interface ALUserClientService : NSObject

@property (nonatomic, strong) ALResponseHandler *responseHandler;

- (void)userLastSeenDetail:(NSNumber *)lastSeenAtTime withCompletion:(void(^)(ALLastSeenSyncFeed *lastSeenSyncFeed))completionMark;

- (void)userDetailServerCall:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark;

- (void)updateUserDisplayName:(ALContact *)contact withCompletion:(void(^)(id jsonResponse, NSError *error))completion;

- (void)markConversationAsReadforContact:(NSString *)userId withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

- (void)userBlockServerCall:(NSString *)userId withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

- (void)userBlockSyncServerCall:(NSNumber *)lastSyncTime withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

- (void)userUnblockServerCall:(NSString *)userId withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

- (void)markMessageAsReadforPairedMessageKey:(NSString *)pairedMessageKey
                              withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

- (void)multiUserSendMessage:(NSDictionary *)messageDictionary
                  toContacts:(NSMutableArray *)contactIdsArray
                    toGroups:(NSMutableArray *)channelKeysArray
              withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

- (void)getListOfRegisteredUsers:(NSNumber *)startTime
                     andPageSize:(NSUInteger)pageSize
                  withCompletion:(void(^)(ALContactsResponse *response, NSError *error))completion;

- (void)fetchOnlineContactFromServer:(NSUInteger)limit withCompletion:(void (^)(id jsonResponse, NSError *error))completion;

- (void)subProcessUserDetailServerCall:(NSString *)paramString
                        withCompletion:(void(^)(NSMutableArray *userDetailArray, NSError *error))completionMark;
- (void)updateUserDisplayName:(NSString *)displayName
             andUserImageLink:(NSString *)imageLink
                   userStatus:(NSString *)status
                     metadata:(NSMutableDictionary *)metadata
               withCompletion:(void (^)(id jsonResponse, NSError *error))completionHandler;

- (void)updateUser:(NSString *)phoneNumber
             email:(NSString *)email
            ofUser: (NSString *)userId
    withCompletion:(void(^)(id jsonResponse, NSError *error))completion;

- (void)subProcessUserDetailServerCallPOST:(ALUserDetailListFeed *)userDetailListFeed
                            withCompletion:(void(^)(NSMutableArray *userDetailArray, NSError *error))completionMark;

- (void)updatePassword:(NSString *)oldPassword
      withNewPassword:(NSString *)newPassword
        withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

- (void)getListOfUsersWithUserName:(NSString *)userName withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

- (void)getMutedUserListWithCompletion:(void(^)(id jsonResponse, NSError *error))completion;

- (void)muteUser:(ALMuteRequest *)muteRequest withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

- (void)reportUserWithMessageKey:(NSString *)messageKey withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

- (void)readCallResettingUnreadCountWithCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion DEPRECATED_ATTRIBUTE;

@end
