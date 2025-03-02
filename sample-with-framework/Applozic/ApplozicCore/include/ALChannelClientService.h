//
//  ALChannelClientService.h
//  Applozic
//
//  Created by devashish on 28/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//  class for server calls

#import "ALAPIResponse.h"
#import "ALChannel.h"
#import "ALChannelCreateResponse.h"
#import "ALChannelDBService.h"
#import "ALChannelFeed.h"
#import "ALChannelFeedResponse.h"
#import "ALChannelSyncResponse.h"
#import "ALChannelUserX.h"
#import "ALConstant.h"
#import "ALMuteRequest.h"
#import "ALRequestHandler.h"
#import "ALResponseHandler.h"
#import <Foundation/Foundation.h>

@interface ALChannelClientService : NSObject

@property (nonatomic, strong) ALResponseHandler *responseHandler;

- (void)createChannel:(NSString *)channelName
  andParentChannelKey:(NSNumber *)parentChannelKey
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
            adminUser:(NSString *)adminUserId
       withCompletion:(void(^)(NSError *error, ALChannelCreateResponse *response))completion;

- (void)addMemberToChannel:(NSString *)userId
        orClientChannelKey:(NSString *)clientChannelKey
             andChannelKey:(NSNumber *)channelKey
            withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

- (void)removeMemberFromChannel:(NSString *)userId
             orClientChannelKey:(NSString *)clientChannelKey
                  andChannelKey:(NSNumber *)channelKey
                 withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

- (void)deleteChannel:(NSNumber *)channelKey
   orClientChannelKey:(NSString *)clientChannelKey
       withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

- (void)leaveChannel:(NSNumber *)channelKey
  orClientChannelKey:(NSString *)clientChannelKey
          withUserId:(NSString *)userId
       andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

- (void)addMultipleUsersToChannel:(NSMutableArray *)channelKeys
                     channelUsers:(NSMutableArray *)channelUsers
                    andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

- (void)updateChannel:(NSNumber *)channelKey
   orClientChannelKey:(NSString *)clientChannelKey
           andNewName:(NSString *)newName
          andImageURL:(NSString *)imageURL
             metadata:(NSMutableDictionary *)metaData
          orChildKeys:(NSMutableArray *)childKeysList
       orChannelUsers:(NSMutableArray *)channelUsers
        andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

- (void)updateChannelMetaData:(NSNumber *)channelKey
           orClientChannelKey:(NSString *)clientChannelKey
                     metadata:(NSMutableDictionary *)metaData
                andCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion;

- (void)getChannelInformationResponse:(NSNumber *)channelKey
                   orClientChannelKey:(NSString *)clientChannelKey
                       withCompletion:(void(^)(NSError *error, ALChannelFeedResponse *response)) completion;

- (void)syncCallForChannel:(NSNumber *)updatedAtTime
      withFetchUserDetails:(BOOL)fetchUserDetails
             andCompletion:(void(^)(NSError *error, ALChannelSyncResponse *response))completion;

- (void)markConversationAsRead:(NSNumber *)channelKey withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

- (void)addChildKeyList:(NSMutableArray *)childKeyList
           andParentKey:(NSNumber *)parentKey
         withCompletion:(void (^)(id jsonResponse, NSError *error))completion;

- (void)removeChildKeyList:(NSMutableArray *)childKeyList
              andParentKey:(NSNumber *)parentKey
            withCompletion:(void (^)(id jsonResponse, NSError *error))completion;

- (void)addClientChildKeyList:(NSMutableArray *)clientChildKeyList
           andClientParentKey:(NSString *)clientParentKey
               withCompletion:(void (^)(id jsonResponse, NSError *error))completion;

- (void)removeClientChildKeyList:(NSMutableArray *)clientChildKeyList
              andClientParentKey:(NSString *)clientParentKey
                  withCompletion:(void (^)(id jsonResponse, NSError *error))completion;

- (void)muteChannel:(ALMuteRequest *)muteRequest withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

- (void)getChannelInfoByIdsOrClientIds:(NSMutableArray *)channelIds
                    orClinetChannelIds:(NSMutableArray *)clientChannelIds
                        withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion;

- (void)getChannelListForCategory:(NSString *)category
                   withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion;

- (void)getAllChannelsForApplications:(NSNumber *)endTime
                       withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion;

- (void)addMemberToContactGroupOfType:(NSString *)contactsGroupId
                          withMembers:(NSMutableArray *)membersArray
                        withGroupType:(short)groupType
                       withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;


- (void)addMemberToContactGroup:(NSString *)contactsGroupId
                    withMembers:(NSMutableArray *)membersArray
                 withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

- (void)getMembersFromContactGroupOfType:(NSString *)contactGroupId
                           withGroupType:(short)groupType
                          withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion;

- (void)getMembersFromContactGroup:(NSString *)contactGroupId withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion;

- (void)removeMemberFromContactGroup:(NSString *)contactsGroupId
                          withUserId:(NSString *)userId
                      withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

- (void)removeMemberFromContactGroupOfType:(NSString *)contactsGroupId
                             withGroupType:(short)groupType
                                withUserId:(NSString *)userId
                            withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

- (void)getMultipleContactGroup:(NSArray *)contactGroupIds withCompletion:(void(^)(NSError *error, NSArray *channel)) completion;

- (void)createChannel:(NSString *)channelName
  andParentChannelKey:(NSNumber *)parentChannelKey
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
           adminUser :(NSString *)adminUserId
      withGroupUsers :(NSMutableArray *)groupRoleUsers
       withCompletion:(void(^)(NSError *error, ALChannelCreateResponse *response))completion;

- (void)getChannelInfo:(NSNumber *)channelKey
    orClientChannelKey:(NSString *)clientChannelKey
        withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion DEPRECATED_MSG_ATTRIBUTE("Use getChannelInformationByResponse:orClientChannelKey:withCompletion from ALChannelService instead");

@end
