//
//  ALChannelClientService.m
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALChannelClientService.h"
#import "ALContactDBService.h"
#import "ALContactService.h"
#import "ALLogger.h"
#import "ALMuteRequest.h"
#import "ALUserClientService.h"
#import "ALUserDetailListFeed.h"
#import "ALUserService.h"
#import "NSString+Encode.h"
#import "ALVerification.h"

static NSString *const CHANNEL_INFO_URL = @"/rest/ws/group/info";
static NSString *const CHANNEL_SYNC_URL = @"/rest/ws/group/v3/list";
static NSString *const CREATE_CHANNEL_URL = @"/rest/ws/group/create";
static NSString *const DELETE_CHANNEL_URL = @"/rest/ws/group/delete";
static NSString *const LEFT_CHANNEL_URL = @"/rest/ws/group/left";
static NSString *const ADD_MEMBER_TO_CHANNEL_URL = @"/rest/ws/group/add/member";
static NSString *const REMOVE_MEMBER_FROM_CHANNEL_URL = @"/rest/ws/group/remove/member";
static NSString *const UPDATE_CHANNEL_URL = @"/rest/ws/group/update";
static NSString *const UPDATE_GROUP_USER = @"/rest/ws/group/user/update";
static NSString *const Add_USERS_TO_MANY_GROUPS = @"/rest/ws/group/add/users";
static NSString *const CHANNEL_INFO_ON_IDS = @"/rest/ws/group/details";
static NSString *const CHANNEL_FILTER_API = @"/rest/ws/group/filter";
static NSString *const CONTACT_FAVOURITE_LIST = @"/rest/ws/group/favourite/list/get";
NSString *const GROUP_FETCH_BATCH_SIZE = @"100";

/************************************************
 SUB GROUP URL : ADD A SINGLE CHILD
 *************************************************/

static NSString *const ADD_SUB_GROUP = @"/rest/ws/group/add/subgroup";
static NSString *const REMOVE_SUB_GROUP = @"/rest/ws/group/remove/subgroup";

/************************************************
 SUB GROUP URL : ADD MULTIPLE CHILD
 *************************************************/

static NSString *const ADD_MULTIPLE_SUB_GROUP = @"/rest/ws/group/add/subgroups";
static NSString *const REMOVE_MULTIPLE_SUB_GROUP = @"/rest/ws/group/remove/subgroups";

@interface ALChannelClientService ()

@end

@implementation ALChannelClientService

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
    self.responseHandler = [[ALResponseHandler alloc] init];
}

#pragma mark - Channel information

- (void)getChannelInfo:(NSNumber *)channelKey
    orClientChannelKey:(NSString *)clientChannelKey
        withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion {
    NSString *channelInfoURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL,CHANNEL_INFO_URL];
    NSString *channelInfoParamString = [NSString stringWithFormat:@"groupId=%@", channelKey];
    if (clientChannelKey) {
        channelInfoParamString = [NSString stringWithFormat:@"clientGroupId=%@", [clientChannelKey urlEncodeUsingNSUTF8StringEncoding]];
    }

    NSMutableURLRequest *channelInfoRequest = [ALRequestHandler createGETRequestWithUrlString:channelInfoURLString paramString:channelInfoParamString];

    [self.responseHandler authenticateAndProcessRequest:channelInfoRequest andTag:@"CHANNEL_INFORMATION" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN CHANNEL_INFORMATION SERVER CALL REQUEST %@", error);
            completion(error, nil);
            return;
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_CHANNEL_INFORMATION :: %@", jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to get channel information response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to get channel information response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            ALChannelCreateResponse *response = [[ALChannelCreateResponse alloc] initWithJSONString:jsonResponse];
            NSMutableArray *members = response.alChannel.membersId;
            ALContactService *contactService = [ALContactService new];
            NSMutableArray *userNotPresentIds =[NSMutableArray new];
            for (NSString *userId in members) {
                if (![contactService isContactExist:userId]) {
                    [userNotPresentIds addObject:userId];
                }
            }
            if (userNotPresentIds.count>0) {
                ALUserService *userService = [ALUserService new];
                [userService getUserDetails:userNotPresentIds withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                    completion(error, response.alChannel);
                }];
            } else {
                completion(error, response.alChannel);
            }
        }
    }];
}

- (void)createChannel:(NSString *)channelName
  andParentChannelKey:(NSNumber *)parentChannelKey
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
            adminUser:(NSString *)adminUserId
       withCompletion:(void(^)(NSError *error, ALChannelCreateResponse *response))completion {
    
    [self createChannel:channelName andParentChannelKey:parentChannelKey orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:type andMetaData:metaData adminUser:adminUserId withGroupUsers:nil withCompletion:^(NSError *error, ALChannelCreateResponse *response) {
        
        completion(error, response);
    }];
}

#pragma mark - Channel Create

- (void)createChannel:(NSString *)channelName
  andParentChannelKey:(NSNumber *)parentChannelKey
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
            adminUser:(NSString *)adminUserId
       withGroupUsers:(NSMutableArray *)groupRoleUsers
       withCompletion:(void(^)(NSError *error, ALChannelCreateResponse *response))completion {
    
    NSString *channelCreateURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, CREATE_CHANNEL_URL];
    NSMutableDictionary *channelDictionary = [NSMutableDictionary new];
    [channelDictionary setObject:channelName forKey:@"groupName"];
    [channelDictionary setObject:memberArray forKey:@"groupMemberList"];
    [channelDictionary setObject:[NSString stringWithFormat:@"%i", type] forKey:@"type"];
    
    if (metaData) {
        [channelDictionary setObject:metaData forKey:@"metadata"];
    }
    
    if (imageLink) {
        [channelDictionary setObject:imageLink forKey:@"imageUrl"];
    }
    
    if (clientChannelKey) {
        [channelDictionary setObject:clientChannelKey forKey:@"clientGroupId"];
    }
    if (parentChannelKey != nil) {
        [channelDictionary setObject:parentChannelKey forKey:@"parentKey"];
    }
    if (adminUserId) {
        [channelDictionary setObject:adminUserId forKey:@"admin"];
    }
    
    if (groupRoleUsers.count) {
        [channelDictionary setObject:groupRoleUsers forKey:@"users"];
    }
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:channelDictionary options:0 error:&error];
    NSString *channelCreateParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING :: %@", channelCreateParamString);
    NSMutableURLRequest *channelCreateRequest = [ALRequestHandler createPOSTRequestWithUrlString:channelCreateURLString paramString:channelCreateParamString];
    [self.responseHandler authenticateAndProcessRequest:channelCreateRequest andTag:@"CREATE_CHANNEL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALChannelCreateResponse *response = nil;

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN CREATE_CHANNEL :: %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_CREATE_CHANNEL :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to create channel response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to get channel information response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALChannelCreateResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);

    }];
}

#pragma mark - Add a new memeber to Channel

- (void)addMemberToChannel:(NSString *)userId
        orClientChannelKey:(NSString *)clientChannelKey
             andChannelKey:(NSNumber *)channelKey
            withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    NSString *addMemberURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, ADD_MEMBER_TO_CHANNEL_URL];
    NSString *addMemberParamString = [NSString stringWithFormat:@"groupId=%@&userId=%@",
                                      channelKey,
                                      [userId urlEncodeUsingNSUTF8StringEncoding]];
    if (clientChannelKey) {
        addMemberParamString = [NSString stringWithFormat:@"clientGroupId=%@&userId=%@",[clientChannelKey urlEncodeUsingNSUTF8StringEncoding],[userId urlEncodeUsingNSUTF8StringEncoding]];
    }
    
    NSMutableURLRequest *addMemberRequest = [ALRequestHandler createGETRequestWithUrlString:addMemberURLString paramString:addMemberParamString];

    [self.responseHandler authenticateAndProcessRequest:addMemberRequest andTag:@"ADD_NEW_MEMBER_TO_CHANNEL" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN ADD_NEW_MEMBER_TO_CHANNEL :: %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_ADD_NEW_MEMBER_TO_CHANNEL :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to create channel response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to get channel information response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];
}

#pragma mark - Remove memeber from Channel

- (void)removeMemberFromChannel:(NSString *)userId
             orClientChannelKey:(NSString *)clientChannelKey
                  andChannelKey:(NSNumber *)channelKey
                 withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    
    NSString *removeMemberURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, REMOVE_MEMBER_FROM_CHANNEL_URL];
    NSString *removeMemberParamString = [NSString stringWithFormat:@"groupId=%@&userId=%@", channelKey,[userId urlEncodeUsingNSUTF8StringEncoding]];
    if (clientChannelKey) {
        removeMemberParamString = [NSString stringWithFormat:@"clientGroupId=%@&userId=%@",[clientChannelKey urlEncodeUsingNSUTF8StringEncoding],[userId urlEncodeUsingNSUTF8StringEncoding]];
    }
    NSMutableURLRequest *removeMemberRequest = [ALRequestHandler createGETRequestWithUrlString:removeMemberURLString paramString:removeMemberParamString];

    [self.responseHandler authenticateAndProcessRequest:removeMemberRequest andTag:@"REMOVE_MEMBER_FROM_CHANNEL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN REMOVE_MEMBER_FROM_CHANNEL :: %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REMOVE_MEMBER_FROM_CHANNEL :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to remove the member from channel response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to remove the member from channel response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];
}

#pragma mark - Delete Channel by admin of Channel

- (void)deleteChannel:(NSNumber *)channelKey
   orClientChannelKey:(NSString *)clientChannelKey
       withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    NSString *deleteChannelURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, DELETE_CHANNEL_URL];
    NSString *deleteChannelParamString = [NSString stringWithFormat:@"groupId=%@", channelKey];
    if (clientChannelKey) {
        deleteChannelParamString = [NSString stringWithFormat:@"clientGroupId=%@",[clientChannelKey urlEncodeUsingNSUTF8StringEncoding]];
    }
    NSMutableURLRequest *deleteChannelRequest = [ALRequestHandler createGETRequestWithUrlString:deleteChannelURLString paramString:deleteChannelParamString];

    [self.responseHandler authenticateAndProcessRequest:deleteChannelRequest andTag:@"DELETE_CHANNEL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN DELETE_CHANNEL SERVER CALL REQUEST :: %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_DELETE_CHANNEL :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to delete the channel the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to delete the channel the response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];
}

#pragma mark - Leave Channel

- (void)leaveChannel:(NSNumber *)channelKey
  orClientChannelKey:(NSString *)clientChannelKey
          withUserId:(NSString *)userId
       andCompletion:(void (^)(NSError *, ALAPIResponse *))completion {
    NSString *leaveChannelURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, LEFT_CHANNEL_URL];
    NSString *leaveChannelParamString = [NSString stringWithFormat:@"groupId=%@&userId=%@",channelKey,[userId urlEncodeUsingNSUTF8StringEncoding]];
    if (clientChannelKey) {
        leaveChannelParamString = [NSString stringWithFormat:@"clientGroupId=%@&userId=%@",[clientChannelKey urlEncodeUsingNSUTF8StringEncoding],[userId urlEncodeUsingNSUTF8StringEncoding]];
    }
    NSMutableURLRequest *leaveChannelRequest = [ALRequestHandler createGETRequestWithUrlString:leaveChannelURLString paramString:leaveChannelParamString];

    [self.responseHandler authenticateAndProcessRequest:leaveChannelRequest andTag:@"LEAVE_FROM_CHANNEL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN LEAVE_FROM_CHANNEL SERVER CALL REQUEST  :: %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_LEAVE_FROM_CHANNEL :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to leave the channel the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to leave the channel the response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }
            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];
}

#pragma mark - Add multiple users in Channels

- (void)addMultipleUsersToChannel:(NSMutableArray *)channelKeys
                     channelUsers:(NSMutableArray *)channelUsers
                    andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    NSString *addMemberURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, Add_USERS_TO_MANY_GROUPS];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    if (channelUsers && channelKeys)  {
        [dictionary setObject:channelUsers forKey:@"userIds"];
        [dictionary setObject:channelKeys forKey:@"clientGroupIds"];
    }
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    NSString *addMemberParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING_CHANNEL_ADD_MANY_USERS :: %@", addMemberParamString);
    
    NSMutableURLRequest *multipleUsersAddRequest = [ALRequestHandler createPOSTRequestWithUrlString:addMemberURLString paramString:addMemberParamString];

    [self.responseHandler authenticateAndProcessRequest:multipleUsersAddRequest andTag:@"ADD_MANY_USERS" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN ADD_MANY_USERS :: %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_ADD_MANY_USERS :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to add member in multiple channels the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to add member in multiple channels the response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];
}

#pragma mark - Update Channel

- (void)updateChannel:(NSNumber *)channelKey
   orClientChannelKey:(NSString *)clientChannelKey
           andNewName:(NSString *)newName
          andImageURL:(NSString *)imageURL
             metadata:(NSMutableDictionary *)metaData
          orChildKeys:(NSMutableArray *)childKeysList
       orChannelUsers:(NSMutableArray *)channelUsers
        andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    NSString *updateChannelURLString;
    if (imageURL && [imageURL isEqualToString:@""]) {
        updateChannelURLString = [NSString stringWithFormat:@"%@%@?resetGroupImageUrl=true", KBASE_URL, UPDATE_CHANNEL_URL];
    } else {
        updateChannelURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, UPDATE_CHANNEL_URL];
    }

    NSMutableDictionary *updateChannelDictionary = [NSMutableDictionary new];
    
    if (newName.length) {
        [updateChannelDictionary setObject:newName forKey:@"newName"];
    }
    if (clientChannelKey.length) {
        [updateChannelDictionary setObject:clientChannelKey forKey:@"clientGroupId"];
    } else {
        [updateChannelDictionary setObject:channelKey forKey:@"groupId"];
    }
    
    if (imageURL) {
        [updateChannelDictionary setObject:imageURL forKey:@"imageUrl"];
    }
    
    if (metaData) {
        [updateChannelDictionary setObject:metaData forKey:@"metadata"];
    }
    
    if (childKeysList.count) {
        [updateChannelDictionary setObject:childKeysList forKey:@"childKeys"];
    }
    if (channelUsers.count) {
        [updateChannelDictionary setObject:channelUsers forKey:@"users"];
    }
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:updateChannelDictionary options:0 error:&error];
    NSString *updateChannelParamString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING_CHANNEL_UPDATE :: %@", updateChannelParamString);
    
    NSMutableURLRequest *updateChannelRequest = [ALRequestHandler createPOSTRequestWithUrlString:updateChannelURLString paramString:updateChannelParamString];

    [self.responseHandler authenticateAndProcessRequest:updateChannelRequest andTag:@"UPDATE_CHANNEL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN UPDATE_CHANNEL :: %@", error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_UPDATE_CHANNEL :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to update channel the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to update channel the response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        }
        completion(error, response);
    }];

}

#pragma mark - Update Channel metadata

- (void)updateChannelMetaData:(NSNumber *)channelKey
           orClientChannelKey:(NSString *)clientChannelKey
                     metadata:(NSMutableDictionary *)metaData
                andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    
    NSString *updateChannelURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, UPDATE_CHANNEL_URL];
    
    NSMutableDictionary *updateChannelDictionary = [NSMutableDictionary new];
    
    if (clientChannelKey.length) {
        [updateChannelDictionary setObject:clientChannelKey forKey:@"clientGroupId"];
    } else {
        [updateChannelDictionary setObject:channelKey forKey:@"groupId"];
    }
    if (metaData) {
        [updateChannelDictionary setObject:metaData forKey:@"metadata"];
    }
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:updateChannelDictionary options:0 error:&error];
    NSString *channelParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];
    
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING_CHANNEL_UPDATE :: %@", channelParamString);

    NSMutableURLRequest *updateChannelRequest = [ALRequestHandler createPOSTRequestWithUrlString:updateChannelURLString paramString:channelParamString];

    [self.responseHandler authenticateAndProcessRequest:updateChannelRequest andTag:@"UPDATE_CHANNEL" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALAPIResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN UPDATE_CHANNEL :: %@", error);
        } else {

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to update channel the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to update channel the response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_UPDATE_CHANNEL :: %@", (NSString *)jsonResponse);
        }
        completion(error, response);
    }];

}

#pragma mark - Channel Sync

- (void)syncCallForChannel:(NSNumber *)updatedAtTime
      withFetchUserDetails:(BOOL)fetchUserDetails
             andCompletion:(void(^)(NSError *error, ALChannelSyncResponse *response))completion {
    NSString *syncChannelURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, CHANNEL_SYNC_URL];
    NSString *syncChannelParamString = nil;

    if (updatedAtTime != nil || updatedAtTime != NULL) {
        syncChannelParamString  = [NSString stringWithFormat:@"updatedAt=%@", updatedAtTime];
    }

    NSMutableURLRequest *syncChannelRequest = [ALRequestHandler createGETRequestWithUrlString:syncChannelURLString paramString:syncChannelParamString];

    [self.responseHandler authenticateAndProcessRequest:syncChannelRequest andTag:@"CHANNEL_SYNCHRONIZATION" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        ALChannelSyncResponse *response = nil;
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN CHANNEL_SYNCHRONIZATION SERVER CALL REQUEST %@", error);
            completion(error, nil);
            return;
        } else {
            ALSLog(ALLoggerSeverityInfo, @"CHANNEL_SYNCHRONIZATION_RESPONSE :: %@", (NSString *)jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to sync channel the response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to sync channel the response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            NSMutableArray *userNotPresentIds = [NSMutableArray new];
            response = [[ALChannelSyncResponse alloc] initWithJSONString:jsonResponse];
            if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
                if (fetchUserDetails) {
                    ALContactService *contactService = [ALContactService new];
                    for (ALChannel *channel in response.alChannelArray) {

                        for (NSString *userId in channel.membersName) {
                            if (![contactService isContactExist:userId]) {
                                [userNotPresentIds addObject:userId];
                            }
                        }
                    }

                    if (userNotPresentIds.count>0) {
                        ALUserService *userService = [ALUserService new];
                        [userService getUserDetails:userNotPresentIds withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                            completion(error, response);
                        }];
                    } else {
                        completion(error, response);
                    }
                } else {
                    completion(error, response);
                }
            } else {
                NSError *error = [NSError
                                  errorWithDomain:@"Applozic"
                                  code:1
                                  userInfo:[NSDictionary
                                            dictionaryWithObject:@"Status fail in response"
                                            forKey:NSLocalizedDescriptionKey]];
                completion(error, nil);
                return;
            }
        }
    }];
}

#pragma mark - Parent and sub groups method

- (void)addChildKeyList:(NSMutableArray *)childKeyList
           andParentKey:(NSNumber *)parentKey
         withCompletion:(void (^)(id json, NSError *error))completion {
    NSString *addChildKeyURLString = [NSString stringWithFormat:@"%@%@",KBASE_URL,ADD_MULTIPLE_SUB_GROUP];
    
    NSString *tempString = @"";
    for (NSNumber *subGroupKey in childKeyList) {
        tempString = [tempString stringByAppendingString:[NSString stringWithFormat:@"&subGroupIds=%@",subGroupKey]];
    }
    
    tempString = [tempString substringFromIndex:1];
    NSString *addChildKeyParamString = [NSString stringWithFormat:@"groupId=%@&%@",parentKey,tempString];
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING_CHANNEL_UPDATE :: %@", addChildKeyParamString);
    NSMutableURLRequest *addChildKeyRequest = [ALRequestHandler createGETRequestWithUrlString:addChildKeyURLString paramString:addChildKeyParamString];
    [self.responseHandler authenticateAndProcessRequest:addChildKeyRequest andTag:@"ADDING_CHILD_TO_PARENT" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR ADDING_CHILD_TO_PARENT :: %@", error);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_ADDING_CHILD_TO_PARENT :: %@", (NSString *)jsonResponse);

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to add child channel in parent key the response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to add child channel in parent key the response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        completion((NSString *)jsonResponse, nil);
    }];
}

- (void)removeChildKeyList:(NSMutableArray *)childKeyList
              andParentKey:(NSNumber *)parentKey
            withCompletion:(void (^)(id json, NSError *error))completion {
    NSString *removeChildKeyURLString = [NSString stringWithFormat:@"%@%@",KBASE_URL,REMOVE_MULTIPLE_SUB_GROUP];
    
    NSString *tempString = @"";
    for (NSNumber *subGroupKey in childKeyList) {
        tempString = [tempString stringByAppendingString:[NSString stringWithFormat:@"&subGroupIds=%@",subGroupKey]];
    }
    
    tempString = [tempString substringFromIndex:1];
    NSString *removeChildKeyParamString = [NSString stringWithFormat:@"groupId=%@&%@",parentKey,tempString];
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING_CHANNEL_UPDATE :: %@", removeChildKeyParamString);
    NSMutableURLRequest *removeChildKeyRequest = [ALRequestHandler createGETRequestWithUrlString:removeChildKeyURLString paramString:removeChildKeyParamString];
    [self.responseHandler authenticateAndProcessRequest:removeChildKeyRequest andTag:@"REMOVE_CHILD_TO_PARENT" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR REMOVE_CHILD_TO_PARENT :: %@", error);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REMOVE_CHILD_TO_PARENT :: %@", (NSString *)jsonResponse);

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to remove child from channel parent key the response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to remove child from channel parent key the response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        completion((NSString *)jsonResponse, nil);
    }];
}

#pragma mark - Add/Remove via Client keys

- (void)addClientChildKeyList:(NSMutableArray *)clientChildKeyList
           andClientParentKey:(NSString *)clientParentKey
               withCompletion:(void (^)(id jsonResponse, NSError *error))completion {
    NSString *addChildKeyURLString = [NSString stringWithFormat:@"%@%@",KBASE_URL,ADD_MULTIPLE_SUB_GROUP];
    
    NSString *tempString = @"";
    for (NSString *subGroupKey in clientChildKeyList) {
        tempString = [tempString stringByAppendingString:[NSString stringWithFormat:@"&clientSubGroupIds=%@",subGroupKey]];
    }
    
    tempString = [tempString substringFromIndex:1];
    NSString *addChildKeyParamString = [NSString stringWithFormat:@"clientGroupId=%@&%@",clientParentKey,tempString];
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING_ADDING_CHILD_TO_PARENT (VIA CLIENT KEY) :: %@", addChildKeyParamString);
    NSMutableURLRequest *addChildKeyRequest = [ALRequestHandler createGETRequestWithUrlString:addChildKeyURLString paramString:addChildKeyParamString];

    [self.responseHandler authenticateAndProcessRequest:addChildKeyRequest andTag:@"ADDING_CHILD_TO_PARENT_VIA_CLIENT_KEY" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR ADDING_CHILD_TO_PARENT (VIA CLIENT KEY) :: %@", error);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_ADDING_CHILD_TO_PARENT (VIA CLIENT KEY) :: %@", (NSString *)jsonResponse);

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to add client child key for channel parent key the response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to add client child key for channel parent key the response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }
        completion((NSString *)jsonResponse, nil);
    }];
}

- (void)removeClientChildKeyList:(NSMutableArray *)clientChildKeyList
              andClientParentKey:(NSString *)clientParentKey
                  withCompletion:(void (^)(id json, NSError *error))completion {
    NSString *removeChildKeyURLString = [NSString stringWithFormat:@"%@%@",KBASE_URL,REMOVE_MULTIPLE_SUB_GROUP];
    
    NSString *tempString = @"";
    for (NSString *subGroupKey in clientChildKeyList) {
        tempString = [tempString stringByAppendingString:[NSString stringWithFormat:@"&clientSubGroupIds=%@",subGroupKey]];
    }
    
    tempString = [tempString substringFromIndex:1];
    NSString *removeChildKeyParamString = [NSString stringWithFormat:@"clientGroupId=%@&%@",clientParentKey,tempString];
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING_ADDING_CHILD_TO_PARENT (VIA CLIENT KEY) :: %@", removeChildKeyParamString);
    NSMutableURLRequest *removeChildKeyRequest = [ALRequestHandler createGETRequestWithUrlString:removeChildKeyURLString paramString:removeChildKeyParamString];

    [self.responseHandler authenticateAndProcessRequest:removeChildKeyRequest andTag:@"REMOVE_CHILD_TO_PARENT_VIA_CLIENT_KEY" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR REMOVE_CHILD_TO_PARENT (VIA CLIENT KEY) :: %@", error);
            completion(nil, error);
            return;
        }

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to remove client child key from channel parent key the response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to remove client child key from channel parent key the response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REMOVE_CHILD_TO_PARENT (VIA CLIENT KEY) :: %@", (NSString *)jsonResponse);
        completion((NSString *)jsonResponse, nil);
    }];
}

#pragma mark - Mark conversation as read

- (void)markConversationAsRead:(NSNumber *)channelKey
                withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion {
    NSString *conversationReadURLString = [NSString stringWithFormat:@"%@/rest/ws/message/read/conversation",KBASE_URL];
    NSString *conversationReadParamString;
    if (channelKey != nil) {
        conversationReadParamString = [NSString stringWithFormat:@"groupId=%@",channelKey];
    }
    NSMutableURLRequest *conversationReadRequest = [ALRequestHandler createGETRequestWithUrlString:conversationReadURLString paramString:conversationReadParamString];

    [self.responseHandler authenticateAndProcessRequest:conversationReadRequest andTag:@"MARK_CONVERSATION_AS_READ" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN MARK_CONVERSATION_AS_READ :: %@", error);
            completion(nil, error);
            return;
        }

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to mark channel as read the response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to mark channel as read the response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_MARK_CONVERSATION_AS_READ :: %@", (NSString *)jsonResponse);
        completion((NSString *)jsonResponse, nil);
    }];
}

#pragma mark - Mute/Unmute Channel

- (void)muteChannel:(ALMuteRequest *)muteRequest
     withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    
    NSString *muteChannelURLString = [NSString stringWithFormat:@"%@%@",KBASE_URL,UPDATE_GROUP_USER];
    NSError *error;
    
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:muteRequest.dictionary options:0 error:&error];
    NSString *muteChannelParamString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *muteChannelRequest = [ALRequestHandler createPOSTRequestWithUrlString:muteChannelURLString paramString:muteChannelParamString];

    [self.responseHandler authenticateAndProcessRequest:muteChannelRequest andTag:@"MUTE_GROUP" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityInfo, @"Channel Mute error :: %@", error);
            completion(nil, error);
            return;
        }

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to mute channel as read the response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to mute channel as read the response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        completion(response, nil);
    }];
    
}

- (void)getChannelInfoByIdsOrClientIds:(NSMutableArray *)channelIds
                    orClinetChannelIds:(NSMutableArray *)clientChannelIds
                        withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion {
    
    NSString *channelListURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL,CHANNEL_INFO_ON_IDS];
    NSString *channelListParamString = nil;
    NSMutableArray *channelInfoList = [[NSMutableArray alloc] init];
    //For client groupId
    if (clientChannelIds) {
        
        for (NSString *clientId in clientChannelIds) {
            if (channelListParamString) {
                channelListParamString = [channelListParamString stringByAppendingString: [NSString stringWithFormat:@"&clientGroupIds=%@",clientId ]];
                
            } else {
                channelListParamString = [NSString stringWithFormat:@"clientGroupIds=%@",clientId];
            }
        }
    }
    
    NSMutableURLRequest *channelListRequest = [ALRequestHandler createGETRequestWithUrlString:channelListURLString paramString:channelListParamString];

    [self.responseHandler authenticateAndProcessRequest:channelListRequest andTag:@"CHANNEL_INFORMATION" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN CHANNEL_INFORMATION SERVER CALL REQUEST %@", error);
            completion(nil, error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_CHANNEL_INFORMATION :: %@", jsonResponse);

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to channel information by client keys or channel keys response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to channel information by client keys or channel keys response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        NSMutableArray *array = (NSMutableArray *)response.response;

        for (NSMutableDictionary *dic  in array) {
            ALChannel *channel = [[ALChannel alloc] initWithDictonary:dic];
            [channelInfoList addObject:channel];
        }
        completion(channelInfoList, error);
    }];
}

#pragma mark - List of Channel with category

- (void)getChannelListForCategory:(NSString *)category
                   withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion {
    
    NSString *channelCategoryURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL,CHANNEL_SYNC_URL];
    NSString *channelCategoryParamString = nil;
    NSMutableArray *channelInfoList = [[NSMutableArray alloc] init];
    
    if (category) {
        channelCategoryParamString = [NSString stringWithFormat:@"category=%@", category];
    } else {
        return;
    }
    
    NSMutableURLRequest *channelCategoryRequest = [ALRequestHandler createGETRequestWithUrlString:channelCategoryURLString paramString:channelCategoryParamString];

    [self.responseHandler authenticateAndProcessRequest:channelCategoryRequest andTag:@"CHANNEL_INFORMATION" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityInfo, @"ERROR IN CHANNEL_LIST SERVER CALL REQUEST %@", error);
            completion(nil,error);
            return;
        }

        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_CHANNEL_INFORMATION :: %@", jsonResponse);

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to get channels for Category response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to get channels for Category response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc ] initWithJSONString:jsonResponse];
        if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
            NSMutableArray *array = (NSMutableArray *)response.response;

            for (NSMutableDictionary *dic  in array) {
                ALChannel *channel = [[ALChannel alloc] initWithDictonary:dic];
                [channelInfoList addObject:channel];
            }
            completion(channelInfoList, nil);
        } else {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to channel list for category"}];
            completion(nil, responseError);
        }
    }];

}

#pragma mark - List of Channels in Application

- (void)getAllChannelsForApplications:(NSNumber *)endTime
                       withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion {
    
    NSString *channelFilterURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL,CHANNEL_FILTER_API];
    NSMutableArray *channelInfoList = [[NSMutableArray alloc] init];
    NSString *channelInfoListParamString = @"";
    
    channelInfoListParamString = [NSString stringWithFormat:@"pageSize=%@", GROUP_FETCH_BATCH_SIZE];

    if (endTime != nil) {
        channelInfoListParamString = [NSString stringWithFormat:@"pageSize=%@&endTime=%@", GROUP_FETCH_BATCH_SIZE , endTime];
    }
    
    NSMutableURLRequest *channelInfoListRequest = [ALRequestHandler createGETRequestWithUrlString:channelFilterURLString paramString:channelInfoListParamString];

    [self.responseHandler authenticateAndProcessRequest:channelInfoListRequest andTag:@"CHANNEL_FILTER" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in Channel filter call Request %@", error);
            completion(nil, error);
            return;
        }

        ALSLog(ALLoggerSeverityInfo, @"Channel response : %@", jsonResponse);
        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to get all channels from application response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to get all channels from application response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];

        if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
            NSNumber *lastFetchTime = [NSNumber numberWithLong:[[response.response valueForKey:@"lastFetchTime"] longValue]];
            [ALUserDefaultsHandler setLastGroupFilterSyncTime:lastFetchTime];

            NSDictionary *channelFeedDictionary = [response.response valueForKey:@"groups"];

            for (NSMutableDictionary *dic in channelFeedDictionary) {
                ALChannel *channel = [[ALChannel alloc] initWithDictonary:dic];
                [channelInfoList addObject:channel];
            }
            completion(channelInfoList, error);
        } else {
            NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                         code:1
                                                     userInfo:@{NSLocalizedDescriptionKey : @"Failed to get list of channel"}];
            completion(nil, responseError);
        }
    }];
}

- (void)addMemberToContactGroupOfType:(NSString *)contactsGroupId
                          withMembers:(NSMutableArray *)membersArray
                        withGroupType:(short)groupType
                       withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    
    NSString *addMemberToContactGroupURLString = [NSString stringWithFormat:@"%@/rest/ws/group/%@/add/members", KBASE_URL,contactsGroupId];
    NSError *error;
    
    NSMutableDictionary *addContactsGroupDictionary = [NSMutableDictionary new];
    [addContactsGroupDictionary setObject:membersArray forKey:@"groupMemberList"];
    [addContactsGroupDictionary setObject:[NSString stringWithFormat:@"%i", groupType] forKey:@"type"];

    NSData *postdata = [NSJSONSerialization dataWithJSONObject:addContactsGroupDictionary options:0 error:&error];
    NSString *addMemberContactGroupParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];

    NSMutableURLRequest *addMemberToContactGroupRequest = [ALRequestHandler createPOSTRequestWithUrlString:addMemberToContactGroupURLString paramString:addMemberContactGroupParamString];

    [self.responseHandler authenticateAndProcessRequest:addMemberToContactGroupRequest andTag:@"ADD_CONTACTS_GROUP_MEMBER_BY_TYPE" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityInfo, @"Add Contcats group with type error :: %@", error);
            completion(nil, error);
            return;
        }

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to add member to contacts group with group type response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to add member to contacts group response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        completion(response, nil);
    }];
}

#pragma mark - Add member to contacts group

- (void)addMemberToContactGroup:(NSString *)contactsGroupId
                    withMembers:(NSMutableArray *)membersArray
                 withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    
    NSString *addMemberToContactGroupURLString = [NSString stringWithFormat:@"%@/rest/ws/group/%@/add", KBASE_URL,contactsGroupId];
    NSError *error;
    
    NSMutableDictionary *addContactsGroupDictionary = [NSMutableDictionary new];
    [addContactsGroupDictionary setObject:membersArray forKey:@"groupMemberList"];

    NSData *postdata = [NSJSONSerialization dataWithJSONObject:addContactsGroupDictionary options:0 error:&error];
    NSString *addMemberToContactGroupParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];

    NSMutableURLRequest *addMemberToContactGroupRequest = [ALRequestHandler createPOSTRequestWithUrlString:addMemberToContactGroupURLString paramString:addMemberToContactGroupParamString];

    [self.responseHandler authenticateAndProcessRequest:addMemberToContactGroupRequest andTag:@"ADD_CONTACTS_GROUP_MEMBER" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityInfo, @" Add Contcats group error:: %@", error);
            completion(nil, error);
            return;
        }

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to add member to contacts group response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to add member to contacts group response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        completion(response, nil);
    }];
}

- (void)getMembersFromContactGroup:(NSString *)contactGroupId
                    withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion {
    [self getMembersFromContactGroupOfType:contactGroupId withGroupType:0 withCompletion:^(NSError *error, ALChannel *channel) {
        
        completion(error, channel);
        
    }];
}

#pragma mark - Get members From contacts group with type

- (void)getMembersFromContactGroupOfType:(NSString *)contactGroupId
                           withGroupType:(short)groupType
                          withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion {
    
    NSString *membersFromContactGroupURLString = [NSString stringWithFormat:@"%@/rest/ws/group/%@/get", KBASE_URL,contactGroupId];
    NSString *membersFromContactGroupParamString = nil;
    
    if (groupType != 0) {
        membersFromContactGroupParamString = [NSString stringWithFormat:@"groupType=%i", groupType];
    }

    NSMutableURLRequest *membersFromContactGroupRequest = [ALRequestHandler createGETRequestWithUrlString:membersFromContactGroupURLString paramString:membersFromContactGroupParamString];

    [self.responseHandler authenticateAndProcessRequest:membersFromContactGroupRequest andTag:@"GET_CONTACTS_GROUP_MEMBERS" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN GET_CONTACTS_GROUP_MEMBERS server call %@", error);
            completion(error, nil);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"GET CONTACTS GROUP_MEMBERS :: %@", jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to get member from contacts group response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to get member from contacts group response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            ALChannelCreateResponse *response = [[ALChannelCreateResponse alloc] initWithJSONString:jsonResponse];
            NSMutableArray *membersUserId = response.alChannel.membersId;
            ALContactService *contactService = [ALContactService new];

            NSMutableArray *userNotPresentIds = [NSMutableArray new];
            for (NSString *userId in membersUserId) {
                if (![contactService isContactExist:userId]) {
                    [userNotPresentIds addObject:userId];
                }
            }
            if (userNotPresentIds.count>0) {
                ALUserService *userService = [ALUserService new];
                [userService getUserDetails:userNotPresentIds withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                    completion(error, response.alChannel);
                }];
            } else {
                completion(error, response.alChannel);
            }
        }
    }];
}

#pragma mark - Remove member From contacts group

- (void)removeMemberFromContactGroup:(NSString *)contactsGroupId
                          withUserId:(NSString *)userId
                      withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    [self removeMemberFromContactGroupOfType:contactsGroupId
                               withGroupType:0 withUserId:userId withCompletion:^(ALAPIResponse *response, NSError *error) {
        completion(response, error);
    }];

}

#pragma mark - Remove member From contacts group with type

- (void)removeMemberFromContactGroupOfType:(NSString *)contactsGroupId
                             withGroupType:(short)groupType
                                withUserId:(NSString *)userId
                            withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {
    
    if (userId == nil) {
        NSError *responseError = [NSError errorWithDomain:@"Applozic"
                                                     code:1
                                                 userInfo:@{NSLocalizedDescriptionKey : @"UserId is nil in removing a member from contact group"}];
        completion(nil, responseError);
        return;
    }
    
    NSString *removeMembersFromContactGroupURL = [NSString stringWithFormat:@"%@/rest/ws/group/%@/remove", KBASE_URL,contactsGroupId];
    
    NSString *removeMembersFromContactGroupParamString = nil;
    
    if (groupType != 0) {
        removeMembersFromContactGroupParamString = [NSString stringWithFormat:@"userId=%@&groupType=%i",userId, groupType];
    }
    
    NSMutableURLRequest *removeMembersFromContactGroupRequest = [ALRequestHandler createGETRequestWithUrlString:removeMembersFromContactGroupURL paramString:removeMembersFromContactGroupParamString];
    [self.responseHandler authenticateAndProcessRequest:removeMembersFromContactGroupRequest andTag:@"REMOVE_CONTACTS_GROUP_MEMBER" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in Remove contacts group :: %@", error);
            completion(nil, error);
            return;
        }

        [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to remove member from contacts group by type response is nil."];

        if (!jsonResponse) {
            NSError *nilResponseError = [NSError
                                         errorWithDomain:@"Applozic"
                                         code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Failed to remove member from contacts group by type response is nil" forKey:NSLocalizedDescriptionKey]];
            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
        completion(response, nil);
    }];
}

#pragma mark - Channel information with response

- (void)getChannelInformationResponse:(NSNumber *)channelKey
                   orClientChannelKey:(NSString *)clientChannelKey
                       withCompletion:(void(^)(NSError *error, ALChannelFeedResponse *response)) completion {
    NSString *channelInfoURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, CHANNEL_INFO_URL];
    NSString *channelInfoParamString = [NSString stringWithFormat:@"groupId=%@", channelKey];
    if (clientChannelKey) {
        channelInfoParamString = [NSString stringWithFormat:@"clientGroupId=%@", clientChannelKey];
    }
    NSMutableURLRequest *channelInfoRequest = [ALRequestHandler createGETRequestWithUrlString:channelInfoURLString paramString:channelInfoParamString];

    [self.responseHandler authenticateAndProcessRequest:channelInfoRequest andTag:@"CHANNEL_INFORMATION" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN CHANNEL_INFORMATION SERVER CALL REQUEST %@", error);
            completion(error, nil);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_CHANNEL_INFORMATION :: %@", jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to get channel information response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to get channel information response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            ALChannelFeedResponse *response = [[ALChannelFeedResponse alloc] initWithJSONString:jsonResponse];

            if ([response.status isEqualToString: AL_RESPONSE_SUCCESS]) {
                NSMutableArray *members = response.alChannel.membersId;
                ALContactService *contactService = [ALContactService new];
                NSMutableArray *userNotPresentIds = [NSMutableArray new];
                for (NSString *userId in members) {
                    if (![contactService isContactExist:userId]) {
                        [userNotPresentIds addObject:userId];
                    }
                }
                if (userNotPresentIds.count>0) {
                    ALUserService *userService = [ALUserService new];
                    [userService getUserDetails:userNotPresentIds withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                        completion(error, response);
                    }];
                } else {
                    completion(error, response);
                }
            } else {
                completion(error, response);
            }
        }
    }];
}

#pragma mark - Get members userIds from contacts group

- (void)getMultipleContactGroup:(NSArray *)contactGroupIds
                 withCompletion:(void(^)(NSError *error, NSArray *channel)) completion {
    
    NSString *multipleContactGroupURLString = [NSString stringWithFormat:@"%@%@",KBASE_URL,CONTACT_FAVOURITE_LIST ];
    
    NSString *multipleContactGroupParamString = [NSString stringWithFormat:@"groupType=%i",9];
    
    for (NSString *contactGroupId in contactGroupIds) {
        multipleContactGroupParamString = [multipleContactGroupParamString stringByAppendingString:[NSString stringWithFormat:@"&groupName=%@", contactGroupId]];
    }
    
    NSMutableURLRequest *multipleContactGroupRequest = [ALRequestHandler createGETRequestWithUrlString:multipleContactGroupURLString paramString:multipleContactGroupParamString];

    [self.responseHandler authenticateAndProcessRequest:multipleContactGroupRequest andTag:@"GET_CONTACTS_GROUP_MEMBERS" WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR IN GET_CONTACTS_GROUP_MEMBERS server call %@", error);
            completion(error, nil);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"GET CONTACTS GROUP_MEMBERS  :: %@", jsonResponse);

            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Failed to get multiple contacts group response is nil."];

            if (!jsonResponse) {
                NSError *nilResponseError = [NSError
                                             errorWithDomain:@"Applozic"
                                             code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Failed to get multiple contacts group response is nil" forKey:NSLocalizedDescriptionKey]];
                completion(nilResponseError, nil);
                return;
            }

            ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];

            NSMutableArray *channelFeedArray = [NSMutableArray new];

            NSArray *channelResponse = apiResponse.response;
            NSMutableArray *userNotPresentIds = [NSMutableArray new];
            ALContactService *contactService = [ALContactService new];

            for (NSDictionary *channelDictionary in channelResponse) {
                ALChannel *channel = [[ALChannel alloc] initWithDictonary:channelDictionary];
                [channelFeedArray addObject:channel];

                for (NSString *userId in channel.membersId) {
                    if (![contactService isContactExist:userId]) {
                        [userNotPresentIds addObject:userId];
                    }
                }
            }

            if (userNotPresentIds.count>0) {
                ALUserService *userService = [ALUserService new];
                [userService getUserDetails:userNotPresentIds withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                    completion(error, channelFeedArray);
                }];
            } else {
                completion(error, channelFeedArray);
            }
        }
    }];
}

@end
