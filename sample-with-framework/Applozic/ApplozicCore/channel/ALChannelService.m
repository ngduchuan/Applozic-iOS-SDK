//
//  ALChannelService.m
//  Applozic
//
//  Created by devashish on 04/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import "ALChannelCreateResponse.h"
#import "ALChannelService.h"
#import "ALChannelUser.h"
#import "ALContactService.h"
#import "ALConversationService.h"
#import "ALLogger.h"
#import "ALMessageClientService.h"
#import "ALMuteRequest.h"
#import "ALRealTimeUpdate.h"
#import "ALVerification.h"

@implementation ALChannelService

static int const AL_CHANNEL_MEMBER_BATCH_SIZE = 100;
NSString *const AL_CHANNEL_MEMBER_SAVE_STATUS = @"AL_CHANNEL_MEMBER_SAVE_STATUS";
NSString *const AL_Updated_Group_Members = @"Updated_Group_Members";
NSString *const AL_MESSAGE_LIST = @"AL_MESSAGE_LIST";
NSString *const AL_MESSAGE_SYNC = @"AL_MESSAGE_SYNC";
NSString *const AL_CHANNEL_MEMBER_CALL_COMPLETED = @"AL_CHANNEL_MEMBER_CALL_COMPLETED";

+ (ALChannelService *)sharedInstance {
    static ALChannelService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ALChannelService alloc] init];
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
    self.channelClientService = [[ALChannelClientService alloc] init];
    self.channelDBService = [[ALChannelDBService alloc] init];
}

- (void)callForChannelServiceForDBInsertion:(NSString *)jsonResponse {
    ALChannelFeed *channelFeed = [[ALChannelFeed alloc] initWithJSONString:jsonResponse];
    [self.channelDBService insertChannel:channelFeed.channelFeedsList];

    //callForChannelProxy inserting in DB...
    ALConversationService *conversationService = [[ALConversationService alloc] init];
    [conversationService addConversations:channelFeed.conversationProxyList];

    [self saveChannelUsersAndChannelDetails:channelFeed.channelFeedsList calledFromMessageList:YES];
}

- (void)processChildGroups:(ALChannel *)channel {
    //Get INFO of Child
    for (NSNumber *channelKey in channel.childKeys) {
        [self getChannelInformationByResponse:channelKey orClientChannelKey:nil withCompletion:^(NSError *error, ALChannel *channel, ALChannelFeedResponse *channelResponse) {

        }];
    }
}

- (ALChannelUserX *)loadChannelUserX:(NSNumber *)channelKey {
    return [self.channelDBService loadChannelUserX:channelKey];
}

#pragma mark - Channel information

- (void)getChannelInformation:(NSNumber *)channelKey
           orClientChannelKey:(NSString *)clientChannelKey
               withCompletion:(void (^)(ALChannel *channel)) completion {

    if (channelKey == nil &&
        !clientChannelKey) {
        completion(nil);
        return;
    }

    ALChannel *channel;
    if (clientChannelKey) {
        channel = [self fetchChannelWithClientChannelKey:clientChannelKey];
    } else {
        channel = [self getChannelByKey:channelKey];
    }
    
    if (channel) {
        completion(channel);
    } else {
        [self.channelClientService getChannelInfo:channelKey orClientChannelKey:clientChannelKey withCompletion:^(NSError *error, ALChannel *channel) {
            
            if (!error) {
                [self createChannelEntry:channel fromMessageList:NO];
            }
            completion(channel);
        }];
    }
}

#pragma mark - Conversation Closed

+ (BOOL)isConversationClosed:(NSNumber *)channelKey {
    ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
    return [channelDBService isConversaionClosed:channelKey];
}

#pragma mark - Channel Deleted

+ (BOOL)isChannelDeleted:(NSNumber *)channelKey {
    ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
    BOOL flag = [channelDBService isChannelDeleted:channelKey];
    return flag;
}

#pragma mark - Channel Muted

+ (BOOL)isChannelMuted:(NSNumber *)channelKey {
    ALChannelService *channelService = [[ALChannelService alloc] init];
    ALChannel *channel = [channelService getChannelByKey:channelKey];
    return [channel isNotificationMuted];
}

#pragma mark - Login User left channel

- (BOOL)isChannelLeft:(NSNumber *)channelKey {
    BOOL flag = [self.channelDBService isChannelLeft:channelKey];
    return flag;
}

#pragma mark - Get channel by channelkey from Database

- (ALChannel *)getChannelByKey:(NSNumber *)channelKey {
    ALChannel *channel = [self.channelDBService loadChannelByKey:channelKey];
    return channel;
}

- (NSMutableArray *)getListOfAllUsersInChannel:(NSNumber *)channelKey {
    return [self.channelDBService getListOfAllUsersInChannel:channelKey];
}

- (NSString *)userNamesWithCommaSeparatedForChannelkey:(NSNumber *)channelKey {
    return [self.channelDBService userNamesWithCommaSeparatedForChannelkey: channelKey];
}

- (NSNumber *)getOverallUnreadCountForChannel {
    return [self.channelDBService getOverallUnreadCountForChannelFromDB];
}

#pragma mark - Get channel by client channelkey from Database

- (ALChannel *)fetchChannelWithClientChannelKey:(NSString *)clientChannelKey {
    ALChannel *channel = [self.channelDBService loadChannelByClientChannelKey:clientChannelKey];
    return channel;
}

- (BOOL)isLoginUserInChannel:(NSNumber *)channelKey {
    NSMutableArray *memberList = [self.channelDBService getListOfAllUsersInChannel:channelKey];
    return ([memberList containsObject:[ALUserDefaultsHandler getUserId]]);
}

#pragma mark - Get list of channels from Database

- (NSMutableArray *)getAllChannelList {
    return [self.channelDBService getAllChannelKeyAndName];
}

- (void)closeGroupConverstion:(NSNumber *)channelKey withCompletion:(void(^)(NSError *error))completion {

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setObject:@"CLOSE" forKey:AL_CHANNEL_CONVERSATION_STATUS];
    
    ALChannelService *channelService = [ALChannelService new];
    [channelService updateChannel:channelKey
                       andNewName:nil
                      andImageURL:nil
               orClientChannelKey:nil
               isUpdatingMetaData:YES
                         metadata:metadata
                      orChildKeys:nil
                   orChannelUsers:nil
                   withCompletion:^(NSError *error) {
        completion(error);
    }];
}

#pragma mark - Parent and sub groups method

- (NSMutableArray *)fetchChildChannelsWithParentKey:(NSNumber *)parentGroupKey {
    return [self.channelDBService fetchChildChannels:parentGroupKey];
}

- (void)addChildKeyList:(NSMutableArray *)childKeyList
           andParentKey:(NSNumber *)parentKey
         withCompletion:(void(^)(id jsonResponse, NSError *error))completion {
    ALSLog(ALLoggerSeverityInfo, @"ADD_CHILD :: PARENT_KEY : %@ && CHILD_KEYs : %@",parentKey,childKeyList.description);
    if (parentKey != nil) {
        __weak typeof(self) weakSelf = self;
        [self.channelClientService addChildKeyList:childKeyList andParentKey:parentKey withCompletion:^(id jsonResponse, NSError *error) {
            
            if (!error) {
                for (NSNumber *childKey in childKeyList) {
                    [weakSelf.channelDBService updateChannelParentKey:childKey andWithParentKey:parentKey isAdding:YES];
                }
            }
            completion(jsonResponse, error);
        }];
    }
}

- (void)removeChildKeyList:(NSMutableArray *)childKeyList
              andParentKey:(NSNumber *)parentKey
            withCompletion:(void(^)(id jsonResponse, NSError *error))completion {
    ALSLog(ALLoggerSeverityInfo, @"REMOVE_CHILD :: PARENT_KEY : %@ && CHILD_KEYs : %@",parentKey,childKeyList.description);
    if (parentKey != nil) {
        [self.channelClientService removeChildKeyList:childKeyList andParentKey:parentKey withCompletion:^(id jsonResponse, NSError *error) {
            
            if (!error) {
                for (NSNumber *childKey in childKeyList) {
                    [self.channelDBService updateChannelParentKey:childKey andWithParentKey:parentKey isAdding:NO];
                }
            }
            completion(jsonResponse, error);
            
        }];
    }
}

#pragma mark - Add/Remove via Client keys

- (void)addClientChildKeyList:(NSMutableArray *)clientChildKeyList
                 andParentKey:(NSString *)clientParentKey
               withCompletion:(void(^)(id jsonResponse, NSError *error))completion {
    ALSLog(ALLoggerSeverityInfo, @"ADD_CHILD :: PARENT_KEY : %@ && CHILD_KEYs (VIA_CLIENT) : %@",clientParentKey,clientChildKeyList.description);
    if (clientParentKey) {
        __weak typeof(self) weakSelf = self;
        [self.channelClientService addClientChildKeyList:clientChildKeyList andClientParentKey:clientParentKey withCompletion:^(id jsonResponse, NSError *error) {
            
            if (!error) {
                for (NSString *childKey in clientChildKeyList) {
                    [weakSelf.channelDBService updateClientChannelParentKey:childKey andWithClientParentKey:clientParentKey isAdding:YES];
                }
            }
            completion(jsonResponse, error);
            
        }];
    }
}

- (void)removeClientChildKeyList:(NSMutableArray *)clientChildKeyList
                    andParentKey:(NSString *)clientParentKey
                  withCompletion:(void(^)(id jsonResponse, NSError *error))completion {
    ALSLog(ALLoggerSeverityInfo, @"REMOVE_CHILD :: PARENT_KEY : %@ && CHILD_KEYs (VIA_CLIENT) : %@",clientParentKey,clientChildKeyList.description);
    if (clientParentKey) {
        [self.channelClientService removeClientChildKeyList:clientChildKeyList andClientParentKey:clientParentKey withCompletion:^(id jsonResponse, NSError *error) {
            
            if (!error) {
                for (NSString *childKey in clientChildKeyList) {
                    [self.channelDBService updateClientChannelParentKey:childKey andWithClientParentKey:clientParentKey isAdding:NO];
                }
            }
            completion(jsonResponse, error);
            
        }];
    }
}


- (void)createChannel:(NSString *)channelName
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
       withCompletion:(void(^)(ALChannel *channel, NSError *error))completion {
    
    /* GROUP META DATA DICTIONARY
     
     NSMutableDictionary *metaData = [self getChannelMetaData];
     
     NOTE : IF GROUP META DATA REQUIRE THEN REPLACE nil BY metaData
     */
    
    [self createChannel:channelName orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:PUBLIC
            andMetaData:nil withCompletion:^(ALChannel *channel, NSError *error) {

        completion(channel, error);
    }];
}

- (void)createChannel:(NSString *)channelName
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
       withCompletion:(void(^)(ALChannel *channel, NSError *error))completion {
    
    [self createChannel:channelName orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:type andMetaData:metaData adminUser:nil withCompletion:^(ALChannel *channel, NSError *error) {
        completion(channel, error);
    }];
}


- (void)createChannel:(NSString *)channelName
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
            adminUser:(NSString *)adminUserId
       withCompletion:(void(^)(ALChannel *channel, NSError *error))completion {
    if (channelName != nil) {
        [self createChannel:channelName orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:type andMetaData:metaData adminUser:adminUserId withGroupUsers:nil withCompletion:^(ALChannel *channel, NSError *error) {
            completion(channel, error);
        }];
    } else {
        ALSLog(ALLoggerSeverityError, @"ERROR : CHANNEL NAME MISSING");
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Channel name is nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, failError);
    }
}


- (void)createChannel:(NSString *)channelName
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
            adminUser:(NSString *)adminUserId
       withGroupUsers:(NSMutableArray *)groupRoleUsers
       withCompletion:(void(^)(ALChannel *channel, NSError *error))completion {
    if (channelName != nil) {
        [self.channelClientService createChannel:channelName
                             andParentChannelKey:nil
                              orClientChannelKey:(NSString *)clientChannelKey
                                  andMembersList:memberArray
                                    andImageLink:imageLink
                                     channelType:(short)type
                                     andMetaData:metaData
                                       adminUser:adminUserId
                                  withGroupUsers:groupRoleUsers
                                  withCompletion:^(NSError *error, ALChannelCreateResponse *response) {

            if (error) {
                ALSLog(ALLoggerSeverityError, @"ERROR_IN_CHANNEL_CREATING :: %@",error);
                completion(nil, error);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *createChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                               userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to create channel.": errorMessage

                                                                                                    forKey:NSLocalizedDescriptionKey]];

                completion(nil, createChannelError);
                return;
            }

            response.alChannel.adminKey = [ALUserDefaultsHandler getUserId];

            if (!response.alChannel) {

                NSError *createChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                               userInfo:[NSDictionary dictionaryWithObject:@"API error failed to create channel response is nil."

                                                                                                    forKey:NSLocalizedDescriptionKey]];

                completion(nil, createChannelError);
                return;
            }

            [self createChannelEntry:response.alChannel fromMessageList:NO];
            completion(response.alChannel, error);

        }];
    } else {
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Channel name is nil" forKey:NSLocalizedDescriptionKey]];
        ALSLog(ALLoggerSeverityError, @"ERROR : CHANNEL NAME MISSING");
        completion(nil, failError);
    }
}


#pragma mark - Create Broadcast Channel

- (void)createBroadcastChannelWithMembersList:(NSMutableArray *)memberArray
                                  andMetaData:(NSMutableDictionary *)metaData
                               withCompletion:(void(^)(ALChannel *channel, NSError *error))completion {
    
    if (memberArray.count) {
        NSMutableArray *nameArray = [NSMutableArray new];
        ALContactService *contactService = [ALContactService new];
        
        for (NSString *userId in memberArray) {
            ALContact *contact = [contactService loadContactByKey:@"userId" value:userId];
            [nameArray addObject:[contact getDisplayName]];
        }
        NSString *broadcastName = @"";
        if (nameArray.count > 10) {
            NSArray *subArray = [nameArray subarrayWithRange:NSMakeRange(0, 10)];
            broadcastName = [subArray componentsJoinedByString:@","];
        } else {
            broadcastName = [nameArray componentsJoinedByString:@","];
        }

        ALChannelInfo *channelInfo = [[ALChannelInfo alloc] init];
        channelInfo.groupName = broadcastName;
        channelInfo.groupMemberList = memberArray;
        channelInfo.type = BROADCAST;
        channelInfo.metadata = metaData;

        [self createChannelWithChannelInfo:channelInfo
                            withCompletion:^(ALChannelCreateResponse *response, NSError *error) {
            if (error) {
                completion(nil, error);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *createChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                               userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to create brodcast channel.": errorMessage

                                                                                                    forKey:NSLocalizedDescriptionKey]];

                completion(nil, createChannelError);
                return;
            }

            [ALVerification verify:response.alChannel != nil withErrorMessage:@"Failed to create broadcast channel response is nil."];

            if (!response.alChannel) {

                NSError *createChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                               userInfo:[NSDictionary dictionaryWithObject:@"API error failed to create brodcast channel response is nil."

                                                                                                    forKey:NSLocalizedDescriptionKey]];

                completion(nil, createChannelError);
                return;
            }
            completion(response.alChannel, nil);
        }];
    } else {
        ALSLog(ALLoggerSeverityError, @"EMPTY_BROADCAST_MEMBER_LIST");
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:0 userInfo:[NSDictionary dictionaryWithObject:@"Empty member list is passed in broadcast." forKey:NSLocalizedDescriptionKey]];
        completion(nil, failError);
    }
}

- (NSMutableDictionary *)getChannelMetaData {
    NSMutableDictionary *groupMetaData = [NSMutableDictionary new];
    
    [groupMetaData setObject:@":adminName created group" forKey:AL_CREATE_GROUP_MESSAGE];
    [groupMetaData setObject:@":userName removed" forKey:AL_REMOVE_MEMBER_MESSAGE];
    [groupMetaData setObject:@":userName added" forKey:AL_ADD_MEMBER_MESSAGE];
    [groupMetaData setObject:@":userName joined" forKey:AL_JOIN_MEMBER_MESSAGE];
    [groupMetaData setObject:@"Group renamed to :groupName" forKey:AL_GROUP_NAME_CHANGE_MESSAGE];
    [groupMetaData setObject:@":groupName icon changed" forKey:AL_GROUP_ICON_CHANGE_MESSAGE];
    [groupMetaData setObject:@":userName left" forKey:AL_GROUP_LEFT_MESSAGE];
    [groupMetaData setObject:@":groupName deleted" forKey:AL_DELETED_GROUP_MESSAGE];
    [groupMetaData setObject:@(NO) forKey:@"HIDE"];
    
    return groupMetaData;
}

- (void)createChannel:(NSString *)channelName
  andParentChannelKey:(NSNumber *)parentChannelKey
   orClientChannelKey:(NSString *)clientChannelKey
       andMembersList:(NSMutableArray *)memberArray
         andImageLink:(NSString *)imageLink
          channelType:(short)type
          andMetaData:(NSMutableDictionary *)metaData
       withCompletion:(void(^)(ALChannel *channel, NSError *error))completion {
    
    [self createChannel:channelName andParentChannelKey:parentChannelKey orClientChannelKey:clientChannelKey andMembersList:memberArray andImageLink:imageLink channelType:type andMetaData:metaData adminUser:nil withCompletion:^(ALChannel *channel, NSError *error) {
        
        completion(channel, error);
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
       withCompletion:(void(^)(ALChannel *channel, NSError *error))completion {
    if (channelName != nil) {
        [self.channelClientService createChannel:channelName
                             andParentChannelKey:parentChannelKey
                              orClientChannelKey:clientChannelKey
                                  andMembersList:memberArray
                                    andImageLink:imageLink
                                     channelType:(short)type
                                     andMetaData:metaData
                                       adminUser:adminUserId
                                  withCompletion:^(NSError *error, ALChannelCreateResponse *response) {

            if (error) {
                ALSLog(ALLoggerSeverityError, @"ERROR_IN_CHANNEL_CREATING :: %@",error);
                completion(nil, error);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *createChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                               userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to create channel.": errorMessage

                                                                                                    forKey:NSLocalizedDescriptionKey]];

                completion(nil, createChannelError);
                return;
            }
            response.alChannel.adminKey = [ALUserDefaultsHandler getUserId];

            [ALVerification verify:response.alChannel != nil withErrorMessage:@"Failed to create channel response is nil."];

            if (!response.alChannel) {

                NSError *createChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                               userInfo:[NSDictionary dictionaryWithObject:@"API error failed to create channel response is nil."

                                                                                                    forKey:NSLocalizedDescriptionKey]];

                completion(nil, createChannelError);
                return;
            }

            [self createChannelEntry:response.alChannel fromMessageList:NO];
            completion(response.alChannel, error);
        }];
    } else {
        ALSLog(ALLoggerSeverityError, @"ERROR : CHANNEL NAME MISSING");
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Parameter channel key or userId is nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, failError);
        return;
    }
}

#pragma mark - Add a new memeber to Channel

- (void)addMemberToChannel:(NSString *)userId
             andChannelKey:(NSNumber *)channelKey
        orClientChannelKey:(NSString *)clientChannelKey
            withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    if ((channelKey != nil || clientChannelKey != nil) && userId != nil) {
        __weak typeof(self) weakSelf = self;
        [self.channelClientService addMemberToChannel:userId orClientChannelKey:clientChannelKey
                                        andChannelKey:channelKey withCompletion:^(NSError *error, ALAPIResponse *response) {

            if (error) {
                completion(error, nil);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *addMemberError =  [NSError errorWithDomain:@"Applozic" code:1
                                                           userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to add member from channel.": errorMessage

                                                                                                forKey:NSLocalizedDescriptionKey]];

                completion(addMemberError, nil);
                return;
            }

            NSError *updateAddMemberError = nil;

            if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
                if (clientChannelKey != nil) {
                    ALChannel *channel = [weakSelf.channelDBService loadChannelByClientChannelKey:clientChannelKey];
                    if (!channel) {
                        updateAddMemberError = [NSError errorWithDomain:@"Applozic"
                                                                   code:1
                                                               userInfo:[NSDictionary dictionaryWithObject:@"Failed to add member from channel does not exist in database." forKey:NSLocalizedDescriptionKey]];
                    } else {
                        updateAddMemberError = [weakSelf.channelDBService addMemberToChannel:userId andChannelKey:channel.key];
                    }
                } else {
                    updateAddMemberError = [weakSelf.channelDBService addMemberToChannel:userId andChannelKey:channelKey];
                }

                if (updateAddMemberError) {
                    completion(updateAddMemberError, nil);
                    return;
                }
            }
            completion(nil, response);
        }];
    } else {
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Parameter channel key or userId is nil while adding a member." forKey:NSLocalizedDescriptionKey]];
        completion(failError, nil);
    }
}

#pragma mark - Remove memeber from Channel

- (void)removeMemberFromChannel:(NSString *)userId
                  andChannelKey:(NSNumber *)channelKey
             orClientChannelKey:(NSString *)clientChannelKey
                 withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    if ((channelKey != nil || clientChannelKey != nil) && userId != nil) {
        [self.channelClientService removeMemberFromChannel:userId orClientChannelKey:clientChannelKey
                                             andChannelKey:channelKey withCompletion:^(NSError *error, ALAPIResponse *response) {

            if (error) {
                completion(error, nil);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *removeMemberError =  [NSError errorWithDomain:@"Applozic" code:1
                                                              userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to remove member from channel.": errorMessage

                                                                                                   forKey:NSLocalizedDescriptionKey]];

                completion(removeMemberError, nil);
                return;
            }

            NSError *updateRemoveMemberError = nil;
            if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {

                if (clientChannelKey != nil) {
                    ALChannel *channel = [self.channelDBService loadChannelByClientChannelKey:clientChannelKey];
                    if (!channel) {
                        updateRemoveMemberError = [NSError errorWithDomain:@"Applozic"
                                                                      code:1
                                                                  userInfo:[NSDictionary dictionaryWithObject:@"Failed to remove member from channel does not exist in database." forKey:NSLocalizedDescriptionKey]];
                    } else {
                        updateRemoveMemberError = [self.channelDBService removeMemberFromChannel:userId andChannelKey:channel.key];
                    }
                } else {
                    updateRemoveMemberError = [self.channelDBService removeMemberFromChannel:userId andChannelKey:channelKey];
                }

                if (updateRemoveMemberError) {
                    completion(updateRemoveMemberError, nil);
                    return;
                }
            }
            completion(updateRemoveMemberError, response);
        }];
    } else {
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Parameter channel key or userId is nil while removing a member from channel." forKey:NSLocalizedDescriptionKey]];
        completion(failError, nil);
    }
}

#pragma mark - Delete Channel by admin of Channel

- (void)deleteChannel:(NSNumber *)channelKey
   orClientChannelKey:(NSString *)clientChannelKey
       withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    if (channelKey != nil || clientChannelKey != nil) {
        [self.channelClientService deleteChannel:channelKey orClientChannelKey:clientChannelKey
                                  withCompletion:^(NSError *error, ALAPIResponse *response) {


            if (error) {
                completion(error, nil);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *deleteChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                               userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to delete channel.": errorMessage

                                                                                                    forKey:NSLocalizedDescriptionKey]];


                completion(deleteChannelError, nil);
                return;
            }

            NSError *updateRemoveMemberError = nil;

            if (clientChannelKey != nil) {
                ALChannel *channel = [self.channelDBService loadChannelByClientChannelKey:clientChannelKey];

                if (!channel) {
                    updateRemoveMemberError = [NSError errorWithDomain:@"Applozic"
                                                                  code:1
                                                              userInfo:[NSDictionary dictionaryWithObject:@"Failed to remove member from channel does not exist in database." forKey:NSLocalizedDescriptionKey]];

                    completion(updateRemoveMemberError, nil);
                    return;
                }
                updateRemoveMemberError = [self.channelDBService deleteChannel:channel.key];
            } else {
                updateRemoveMemberError = [self.channelDBService deleteChannel:channelKey];
            }

            if (updateRemoveMemberError) {
                completion(updateRemoveMemberError, nil);
                return;
            }
            completion(nil, response);
        }];
    } else {
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Parameter channel key and clientChannelKey is nil while deleting channel." forKey:NSLocalizedDescriptionKey]];
        completion(failError, nil);
    }
}

- (BOOL)checkAdmin:(NSNumber *)channelKey {
    ALChannel *channel = [self.channelDBService loadChannelByKey:channelKey];
    return [channel.adminKey isEqualToString:[ALUserDefaultsHandler getUserId]];
}

#pragma mark - Leave Channel

- (void)leaveChannel:(NSNumber *)channelKey
           andUserId:(NSString *)userId
  orClientChannelKey:(NSString *)clientChannelKey
      withCompletion:(void(^)(NSError *error))completion {

    [self leaveChannelWithChannelKey:channelKey
                           andUserId:userId
                  orClientChannelKey:clientChannelKey
                      withCompletion:^(NSError * _Nullable error, ALAPIResponse * _Nullable response) {
        completion(error);
    }];
}

- (NSError *)proccessLeaveResponse:(NSNumber *)channelKey
                         andUserId:(NSString *)userId
                orClientChannelKey:(NSString *)clientChannelKey
                      withResponse:(ALAPIResponse *)response {
    
    if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

        NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

        return [NSError errorWithDomain:@"Applozic" code:1
                               userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to leave from channel.": errorMessage

                                                                    forKey:NSLocalizedDescriptionKey]];
    }

    NSError *updateLeaveError = nil;

    if (clientChannelKey != nil) {
        ALChannel *channel = [self.channelDBService loadChannelByClientChannelKey:clientChannelKey];
        if (!channel) {
            return [NSError errorWithDomain:@"Applozic"
                                       code:1
                                   userInfo:[NSDictionary dictionaryWithObject:@"Failed to leave from channel does not exist in database." forKey:NSLocalizedDescriptionKey]];
        }
        updateLeaveError = [self.channelDBService removeMemberFromChannel:userId andChannelKey:channel.key];
        [self.channelDBService setLeaveFlag:YES forChannel:channel.key];
    } else {
        updateLeaveError = [self.channelDBService removeMemberFromChannel:userId andChannelKey:channelKey];
        [self.channelDBService setLeaveFlag:YES forChannel:channelKey];
    }
    return updateLeaveError;
}

#pragma mark - Leave Channel with response

- (void)leaveChannelWithChannelKey:(NSNumber *)channelKey
                         andUserId:(NSString *)userId
                orClientChannelKey:(NSString *)clientChannelKey
                    withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {
    if ((channelKey != nil || clientChannelKey != nil) && userId != nil) {
        [self.channelClientService leaveChannel:channelKey
                             orClientChannelKey:clientChannelKey
                                     withUserId:userId
                                  andCompletion:^(NSError *error, ALAPIResponse *response) {

            if (error) {
                completion(error, nil);
                return;
            }

            NSError *updateLeaveError = [self proccessLeaveResponse:channelKey andUserId:userId orClientChannelKey:clientChannelKey withResponse:response];
            if (updateLeaveError) {
                completion(updateLeaveError, nil);
                return;
            }
            completion(nil, response);
        }];
    } else {
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Parameter channel key or userId is nil while leaving Channel." forKey:NSLocalizedDescriptionKey]];
        completion(failError, nil);
    }
}

#pragma mark - Add multiple users in Channels

- (void)addMultipleUsersToChannel:(NSMutableArray *)channelKeys
                     channelUsers:(NSMutableArray *)channelUsers
                    andCompletion:(void(^)(NSError *error))completion {
    if (channelKeys != nil && channelUsers != nil) {
        __weak typeof(self) weakSelf = self;
        [self.channelClientService addMultipleUsersToChannel:channelKeys channelUsers:channelUsers andCompletion:^(NSError *error, ALAPIResponse *response) {

            if (error) {
                completion(error);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
                for (int i = 0; i<[channelUsers count]; i++) {
                    [weakSelf.channelDBService addMemberToChannel:channelUsers[i] andChannelKey:channelKeys.firstObject];
                }
                completion(nil);
            } else {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *addMemberError = [NSError errorWithDomain:@"Applozic" code:1
                                                          userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to add a member in channel.": errorMessage

                                                                                               forKey:NSLocalizedDescriptionKey]];

                completion(addMemberError);
            }
        }];
    }
}

#pragma mark - Update Channel

- (void)updateChannel:(NSNumber *)channelKey
           andNewName:(NSString *)newName
          andImageURL:(NSString *)imageURL
   orClientChannelKey:(NSString *)clientChannelKey
   isUpdatingMetaData:(BOOL)flag
             metadata:(NSMutableDictionary *)metaData
          orChildKeys:(NSMutableArray *)childKeysList
       orChannelUsers:(NSMutableArray *)channelUsers
       withCompletion:(void(^)(NSError *error))completion {

    [self updateChannelWithChannelKey:channelKey
                           andNewName:newName
                          andImageURL:imageURL
                   orClientChannelKey:clientChannelKey
                   isUpdatingMetaData:flag
                             metadata:metaData
                          orChildKeys:childKeysList
                       orChannelUsers:channelUsers
                       withCompletion:^(NSError * _Nullable error, ALAPIResponse * _Nullable response) {
        completion(error);
    }];
}

#pragma mark - Update Channel with response

- (void)updateChannelWithChannelKey:(NSNumber *)channelKey
                         andNewName:(NSString *)newName
                        andImageURL:(NSString *)imageURL
                 orClientChannelKey:(NSString *)clientChannelKey
                 isUpdatingMetaData:(BOOL)flag
                           metadata:(NSMutableDictionary *)metaData
                        orChildKeys:(NSMutableArray *)childKeysList
                     orChannelUsers:(NSMutableArray *)channelUsers
                     withCompletion:(void(^)(NSError *error, ALAPIResponse *response))completion {

    if (channelKey == nil &&
        !clientChannelKey) {
        NSError *failError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Parameter channel key or clientChannelKey is nil while updating channel." forKey:NSLocalizedDescriptionKey]];
        completion(failError, nil);
        return;
    }

    [self.channelClientService updateChannel:channelKey
                          orClientChannelKey:clientChannelKey
                                  andNewName:newName
                                 andImageURL:imageURL
                                    metadata:metaData
                                 orChildKeys:childKeysList
                              orChannelUsers:(NSMutableArray *)channelUsers
                               andCompletion:^(NSError *error, ALAPIResponse *response) {

        if (error) {
            completion(error, nil);
            return;
        }

        NSError *updateError = [self proccessUpdateChannelResponse:channelKey
                                                        andNewName:newName
                                                       andImageURL:imageURL
                                                orClientChannelKey:clientChannelKey
                                                isUpdatingMetaData:flag
                                                          metadata:metaData
                                                       orChildKeys:childKeysList
                                                    orChannelUsers:channelUsers
                                                      withResponse:response];

        if (updateError) {
            completion(updateError, nil);
            return;
        }
        completion(nil, response);
    }];
}

- (NSError *)proccessUpdateChannelResponse:(NSNumber *)channelKey
                                andNewName:(NSString *)newName
                               andImageURL:(NSString *)imageURL
                        orClientChannelKey:(NSString *)clientChannelKey
                        isUpdatingMetaData:(BOOL)flag
                                  metadata:(NSMutableDictionary *)metaData
                               orChildKeys:(NSMutableArray *)childKeysList
                            orChannelUsers:(NSMutableArray *)channelUsers
                             withResponse :(ALAPIResponse *) response {
    
    if ([response.status isEqualToString:AL_RESPONSE_SUCCESS]) {
        ALChannel *channel = nil;
        if (clientChannelKey != nil) {
            channel = [self.channelDBService loadChannelByClientChannelKey:clientChannelKey];
        } else {
            channel = [self.channelDBService loadChannelByKey:channelKey];
        }

        if (!channel) {
            NSError *notFoundError = [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Failed to update channel does not exist." forKey:NSLocalizedDescriptionKey]];
            return notFoundError;
        }

        return [self.channelDBService updateChannel:channel.key andNewName:newName orImageURL:imageURL orChildKeys:childKeysList isUpdatingMetaData:flag orChannelUsers:channelUsers];
    }


    NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

    return [NSError errorWithDomain:@"Applozic" code:1
                           userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to update channel.": errorMessage

                                                                forKey:NSLocalizedDescriptionKey]];

}

#pragma mark - Update Channel metadata

- (void)updateChannelMetaData:(NSNumber *)channelKey
           orClientChannelKey:(NSString *)clientChannelKey
                     metadata:(NSMutableDictionary *)metaData
               withCompletion:(void(^)(NSError *error))completion {

    if (channelKey == nil &&
        !clientChannelKey) {

        NSError *failError = [NSError errorWithDomain:@"Applozic"
                                                 code:1
                                             userInfo:[NSDictionary dictionaryWithObject:@"Parameter channel or client key is nil" forKey:NSLocalizedDescriptionKey]];
        completion(failError);
        return;
    }

    [self.channelClientService updateChannelMetaData:channelKey
                                  orClientChannelKey:clientChannelKey
                                            metadata:metaData
                                       andCompletion:^(NSError *error, ALAPIResponse *response) {

        if (error) {
            completion(error);
            return;
        }

        NSError *updateMetadataError = nil;

        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

            NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

            updateMetadataError = [NSError errorWithDomain:@"Applozic" code:1
                                                  userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to update channel metadata.": errorMessage

                                                                                       forKey:NSLocalizedDescriptionKey]];
            completion(updateMetadataError);
            return;
        }
        if (clientChannelKey != nil) {
            ALChannel *channel = [self.channelDBService loadChannelByClientChannelKey:clientChannelKey];
            if (!channel) {
                updateMetadataError = [NSError errorWithDomain:@"Applozic" code:1
                                                      userInfo:[NSDictionary dictionaryWithObject:@"Failed to update channel metadata channel does not exist in database."
                                                                                           forKey:NSLocalizedDescriptionKey]];
                completion(updateMetadataError);
                return;
            }
            updateMetadataError = [self.channelDBService updateChannelMetaData:channel.key metaData:metaData];
        } else if (channelKey != nil) {
            updateMetadataError = [self.channelDBService updateChannelMetaData:channelKey metaData:metaData];
        }
        completion(updateMetadataError);
    }];
}

#pragma mark - Channel Sync

- (void)syncCallForChannel {
    [self syncCallForChannelWithDelegate:nil
                          withCompletion:^(ALChannelSyncResponse *response, NSError *error) {

    }];
}

-(void)syncCallForChannelWithDelegate:(id<ApplozicUpdatesDelegate>)delegate
                       withCompletion:(void (^)(ALChannelSyncResponse *response, NSError *error))completion {

    NSNumber *updateAtTime = [ALUserDefaultsHandler getLastSyncChannelTime];

    [self.channelClientService syncCallForChannel:updateAtTime
                             withFetchUserDetails:YES
                                    andCompletion:^(NSError *error, ALChannelSyncResponse *response) {

        if (error) {
            completion(nil, error);
            return;
        }

        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

            NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

            NSError *syncChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                         userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to sync channel.": errorMessage

                                                                                              forKey:NSLocalizedDescriptionKey]];

            completion(nil, syncChannelError);
            return;
        }

        [ALUserDefaultsHandler setLastSyncChannelTime:response.generatedAt];
        [self createChannelsAndUpdateInfo:response.alChannelArray withDelegate:delegate];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_CHANNEL_NAME" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_CHANNEL_METADATA" object:nil];

        completion(response, error);
    }];

}

#pragma mark - Mark conversation as read

- (void)markConversationAsRead:(NSNumber *)channelKey withCompletion:(void (^)(NSString *response, NSError *error))completion {

    if (channelKey == nil) {
        NSError *error = [NSError
                          errorWithDomain:@"Applozic"
                          code:1
                          userInfo:[NSDictionary dictionaryWithObject:@"Failed to mark conversation read the channelKey is nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, error);
        return;
    }

    [self setUnreadCountZeroForGroupID:channelKey];
    
    NSUInteger count = [self.channelDBService markConversationAsRead:channelKey];
    ALSLog(ALLoggerSeverityInfo, @"Found %ld messages for marking as read.", (unsigned long)count);
    
    if (count == 0) {
        completion(AL_RESPONSE_SUCCESS, nil);
        return;
    }
    
    [self.channelClientService markConversationAsRead:channelKey withCompletion:^(NSString *response, NSError *error) {
        completion(response,error);
    }];
    
}

- (void)setUnreadCountZeroForGroupID:(NSNumber *)channelKey {
    [self.channelDBService updateUnreadCountChannel:channelKey unreadCount:[NSNumber numberWithInt:0]];
}

#pragma mark - Mute/Unmute Channel

- (void)muteChannel:(ALMuteRequest *)muteRequest withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {

    if (!muteRequest) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic" code:1
                                            userInfo:[NSDictionary dictionaryWithObject:@"Failed to mute channel ALMuteRequest is nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, nilError);
        return;
    }

    if (muteRequest.notificationAfterTime == nil || (muteRequest.id == nil && !muteRequest.clientGroupId)) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic" code:1
                                            userInfo:[NSDictionary dictionaryWithObject:@"Failed to mute channel where notificationAfterTime nil" forKey:NSLocalizedDescriptionKey]];
        completion(nil, nilError);
        return;
    }

    [self.channelClientService muteChannel:muteRequest withCompletion:^(ALAPIResponse *response, NSError *error) {


        if (error) {
            completion(nil, error);
            return;
        }

        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

            NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

            NSError *muteChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                         userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to mute the channel.": errorMessage

                                                                                              forKey:NSLocalizedDescriptionKey]];

            completion(nil, muteChannelError);
            return;
        }

        NSError *updateError = [self.channelDBService updateMuteAfterTime:muteRequest.notificationAfterTime andChnnelKey:muteRequest.id];
        if (updateError) {
            completion(nil, updateError);
            return;
        }
        completion(response, nil);
    }];
}

- (NSError *)updateMuteAfterTime:(NSNumber *)notificationAfterTime
                    andChnnelKey:(NSNumber *)channelKey {
    return [self.channelDBService updateMuteAfterTime:notificationAfterTime andChnnelKey:channelKey];
}

- (void)getChannelInfoByIdsOrClientIds:(NSMutableArray *)channelIds
                    orClinetChannelIds:(NSMutableArray *) clientChannelIds
                        withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion {

    [self.channelClientService getChannelInfoByIdsOrClientIds:channelIds orClinetChannelIds:clientChannelIds
                                               withCompletion:^(NSMutableArray *channelInfoList, NSError *error) {

        for (ALChannel *channel in channelInfoList) {
            [self createChannelEntry:channel fromMessageList:NO];
        }
        completion(channelInfoList,error);
    }];
    
}

#pragma mark - List of Channel with category
- (void)getChannelListForCategory:(NSString *)category
                   withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion {

    if (category.length == 0) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Category is empty while fetching list channels under category"}];

        completion(nil, nilError);
        return;
    }

    [self.channelClientService getChannelListForCategory:category withCompletion:^(NSMutableArray *channelInfoList, NSError *error) {

        for (ALChannel *channel in channelInfoList) {
            [self createChannelEntry:channel fromMessageList:NO];
        }
        completion(channelInfoList,error);
    }];
}

#pragma mark - List of Channels in Application

- (void)getAllChannelsForApplications:(NSNumber *)endTime withCompletion:(void(^)(NSMutableArray *channelInfoList, NSError *error))completion {

    [self.channelClientService getAllChannelsForApplications:endTime withCompletion:^(NSMutableArray *channelInfoList, NSError *error) {
        
        for (ALChannel *channel in channelInfoList) {
            [self createChannelEntry:channel fromMessageList:NO];
        }
        completion(channelInfoList,error);
    }];
}

#pragma mark - Add member to contacts group with type

- (void)addMemberToContactGroupOfType:(NSString *)contactsGroupId
                          withMembers: (NSMutableArray *)membersArray
                        withGroupType:(short) groupType
                       withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {

    if (contactsGroupId.length == 0) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Contacts GroupId is empty while adding a member to contacts group"}];

        completion(nil, nilError);
        return;
    }

    [self.channelClientService addMemberToContactGroupOfType:contactsGroupId withMembers:membersArray withGroupType:groupType withCompletion:^(ALAPIResponse *response, NSError *error) {
        
        completion(response, error);
        
    }];
}

#pragma mark - Add member to contacts group

- (void)addMemberToContactGroup:(NSString *)contactsGroupId
                    withMembers:(NSMutableArray *)membersArray
                 withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {

    if (contactsGroupId.length == 0) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Contacts GroupId is empty while adding a member to contacts group"}];

        completion(nil, nilError);
        return;
    }

    [self.channelClientService addMemberToContactGroup:contactsGroupId
                                           withMembers:membersArray
                                        withCompletion:^(ALAPIResponse *response, NSError *error) {
        completion(response, error);
    }];
}

#pragma mark - Get members From contacts group with type

- (void)getMembersFromContactGroupOfType:(NSString *)contactsGroupId
                           withGroupType:(short)groupType
                          withCompletion:(void(^)(NSError *error, ALChannel *channel)) completion {


    if (!contactsGroupId) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Contacts GroupId is nil while list fetching a list of memebers from contacts group"}];

        completion(nilError, nil);
        return;
    }
    
    if (contactsGroupId) {
        [self.channelClientService getMembersFromContactGroupOfType:contactsGroupId withGroupType:groupType withCompletion:^(NSError *error, ALChannel *channel) {

            if (!error && channel) {
                ALChannelService *channelService = [[ALChannelService alloc] init];
                [channelService createChannelEntry:channel fromMessageList:NO];
                completion(error, channel);
            } else {
                completion(error, nil);
            }
        }];
    }
}

- (NSMutableArray *)getListOfAllUsersInChannelByNameForContactsGroup:(NSString *)channelName {
    
    if (channelName == nil) {
        return nil;
    }
    return [self.channelDBService getListOfAllUsersInChannelByNameForContactsGroup:channelName];
}

#pragma mark - Remove member From contacts group

- (void)removeMemberFromContactGroup:(NSString *)contactsGroupId
                          withUserId:(NSString *)userId
                      withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {

    if (contactsGroupId.length == 0 || userId.length == 0) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Contacts GroupId or userId is empty while removing a memeber from contacts group"}];

        completion(nil, nilError);
        return;
    }

    [self.channelClientService removeMemberFromContactGroup:contactsGroupId withUserId:userId withCompletion:^(ALAPIResponse *response, NSError *error) {
        completion(response, error);
    }];
}

#pragma mark - Remove member From contacts group with type

- (void)removeMemberFromContactGroupOfType:(NSString *)contactsGroupId
                             withGroupType:(short)groupType
                                withUserId:(NSString *)userId
                            withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion {

    if (contactsGroupId.length == 0 || userId.length == 0) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Contacts GroupId or userId is empty while removing a member from contacts group"}];

        completion(nil, nilError);
        return;
    }
    
    [self.channelClientService removeMemberFromContactGroupOfType:contactsGroupId
                                                    withGroupType:groupType
                                                       withUserId:userId
                                                   withCompletion:^(ALAPIResponse *response, NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }

        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

            NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

            NSError *channelInfoError =  [NSError errorWithDomain:@"Applozic" code:1
                                                         userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to remove member from contacts group": errorMessage

                                                                                              forKey:NSLocalizedDescriptionKey]];

            completion(nil, channelInfoError);
            return;
        }

        DB_CHANNEL *dbChannel = [self.channelDBService getContactsGroupChannelByName:contactsGroupId];

        if (dbChannel != nil) {
            [self.channelDBService removeMemberFromChannel:userId andChannelKey:dbChannel.channelKey];
        }
        completion(response, error);
    }];
    
}

#pragma mark - Get members userIds from contacts group

- (void)getMembersIdsForContactGroups:(NSArray *)contactGroupIds
                       withCompletion:(void(^)(NSError *error, NSArray *membersArray)) completion {
    NSMutableArray *memberUserIds = [NSMutableArray new];
    
    if (contactGroupIds) {
        [self.channelClientService getMultipleContactGroup:contactGroupIds withCompletion:^(NSError *error, NSArray *channels) {
            
            if (channels) {
                for (ALChannel *channel in channels) {
                    ALChannelService *channelService = [[ALChannelService alloc] init];
                    [channelService createChannelEntry:channel fromMessageList:NO];
                    [memberUserIds addObjectsFromArray:channel.membersId];
                }
                completion(nil, memberUserIds);
            } else {
                completion(error, nil);
            }
        }];
    }
}

#pragma mark - Channel information with response

- (void)getChannelInformationByResponse:(NSNumber *)channelKey
                     orClientChannelKey:(NSString *)clientChannelKey
                         withCompletion:(void (^)(NSError *error, ALChannel *channel, ALChannelFeedResponse *channelResponse)) completion {

    if (channelKey == nil &&
        !clientChannelKey) {
        NSError *nilError = [NSError errorWithDomain:@"Applozic"
                                                code:1
                                            userInfo:@{NSLocalizedDescriptionKey:@"Channel key or client channel key is nil"}];

        completion(nilError, nil, nil);
        return;
    }

    ALChannel *channel;
    if (clientChannelKey) {
        channel = [self fetchChannelWithClientChannelKey:clientChannelKey];
    } else {
        channel = [self getChannelByKey:channelKey];
    }
    
    if (channel) {
        completion(nil, channel, nil);
    } else {
        [self.channelClientService getChannelInformationResponse:channelKey
                                              orClientChannelKey:clientChannelKey
                                                  withCompletion:^(NSError *error, ALChannelFeedResponse *response) {


            if (error) {
                completion(error, nil, nil);
                return;
            }

            if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

                NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

                NSError *channelInfoError =  [NSError errorWithDomain:@"Applozic" code:1
                                                             userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to get channel information.": errorMessage

                                                                                                  forKey:NSLocalizedDescriptionKey]];

                completion(channelInfoError, nil, nil);
                return;
            }

            [self createChannelEntry:response.alChannel fromMessageList:NO];
            completion(nil, response.alChannel, nil);
        }];
    }
}

- (NSDictionary *)metadataToTurnOffActionMessagesNotifications {
    return [self metadataToTurnOffActionMessagesNotificationsAndhideMessages:NO];
}

- (NSDictionary *)metadataToHideActionMessagesAndTurnOffNotifications {
    return [self metadataToTurnOffActionMessagesNotificationsAndhideMessages:YES];
}

- (NSDictionary *)metadataToTurnOffActionMessagesNotificationsAndhideMessages:(BOOL)hideMessages {

    // In case of just turning off the notifications, only 'Alert' key needs to be false and empty string for action messages.

    NSDictionary *basicMetadata = @{AL_CREATE_GROUP_MESSAGE:@"",
                                    AL_REMOVE_MEMBER_MESSAGE:@"",
                                    AL_ADD_MEMBER_MESSAGE:@"",
                                    AL_JOIN_MEMBER_MESSAGE:@"",
                                    AL_GROUP_NAME_CHANGE_MESSAGE:@"",
                                    AL_GROUP_ICON_CHANGE_MESSAGE:@"",
                                    AL_GROUP_LEFT_MESSAGE:@"",
                                    AL_DELETED_GROUP_MESSAGE:@"",
                                    @"Alert":@"false"
    };
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:basicMetadata];
    if (!hideMessages) {
        return metadata;
    }
    metadata[@"hide"] = @"true";
    return metadata;
}

#pragma mark - Channel Create with response

- (void)createChannelWithChannelInfo:(ALChannelInfo *)channelInfo
                      withCompletion:(void(^)(ALChannelCreateResponse *response, NSError *error))completion {
    
    if (!channelInfo.type) {
        channelInfo.type = PUBLIC;
    }
    
    if (!channelInfo.groupMemberList) {
        NSError *memberError = [NSError errorWithDomain:@"Applozic"
                                                   code:2
                                               userInfo:@{NSLocalizedDescriptionKey:@"Nil in group member list"}];
        
        completion(nil, memberError);
        return;
    }
    
    [self.channelClientService createChannel:channelInfo.groupName
                         andParentChannelKey:nil
                          orClientChannelKey:channelInfo.clientGroupId
                              andMembersList:channelInfo.groupMemberList
                                andImageLink:channelInfo.imageUrl
                                 channelType:channelInfo.type
                                 andMetaData:channelInfo.metadata
                                   adminUser:channelInfo.admin
                              withGroupUsers:channelInfo.groupRoleUsers
                              withCompletion:^(NSError *error, ALChannelCreateResponse *response) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"ERROR_IN_CHANNEL_CREATING :: %@",error);
            completion(nil, error);
            return;
        }
        if ([response.status isEqualToString:AL_RESPONSE_ERROR]) {

            NSString *errorMessage =  [response.errorResponse errorDescriptionMessage];

            NSError *createChannelError =  [NSError errorWithDomain:@"Applozic" code:1
                                                           userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"API error failed to create channel.": errorMessage

                                                                                                forKey:NSLocalizedDescriptionKey]];

            completion(nil, createChannelError);
            return;
        }
        response.alChannel.adminKey = [ALUserDefaultsHandler getUserId];
        [self createChannelEntry:response.alChannel fromMessageList:NO];
        completion(response, error);
    }];
}

- (void)updateConversationReadWithGroupId:(NSNumber *)channelKey withDelegate:(id<ApplozicUpdatesDelegate>)delegate {
    
    [self setUnreadCountZeroForGroupID:channelKey];
    if (delegate) {
        [delegate conversationReadByCurrentUser:nil withGroupId:channelKey];
    }
    NSDictionary *notificationDictionary = @{@"channelKey":channelKey};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update_unread_count" object:notificationDictionary];
}

- (void)createChannelEntry:(ALChannel *)channel fromMessageList:(BOOL)isFromMessageList {
    if (!channel) {
        return;
    }
    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    if (!isFromMessageList) {
        channel.unreadCount = [NSNumber numberWithInt:0];
    }
    [self.channelDBService createChannelEntity:channel];

    [databaseHandler saveContext];

    NSMutableArray <ALChannel *> *channelFeedArray = [[NSMutableArray alloc] init];
    [channelFeedArray addObject:channel];
    [self saveChannelUsersAndChannelDetails:channelFeedArray  calledFromMessageList:isFromMessageList];
}

- (void)saveChannelUsersAndChannelDetails:(NSMutableArray <ALChannel *>*)channelFeedsList calledFromMessageList:(BOOL)isFromMessageList {

    if (!channelFeedsList.count) {
        return;
    }

    ALDBHandler *databaseHandler = [ALDBHandler sharedInstance];
    dispatch_group_t group = dispatch_group_create();

    for (ALChannel *channel in channelFeedsList) {
        dispatch_group_enter(group);

        if (channel.membersName == nil) {
            channel.membersName = channel.membersId;
        }
        // As running in a background thread it's important to check if the user is loggedIn otherwise it will continue the operation even after logout
        if (!ALUserDefaultsHandler.isLoggedIn) {
            ALSLog(ALLoggerSeverityInfo, @"User is not login returing from channel");
            dispatch_group_leave(group);
            return;
        }

        [self.channelDBService deleteMembers:channel.key];

        NSPersistentContainer *container = databaseHandler.persistentContainer;

        [container performBackgroundTask:^(NSManagedObjectContext *context) {

            int count = 0;
            __block BOOL isProccessFailed = NO;
            for (ALChannelUser *channelUser in channel.groupUsers) {

                if (isProccessFailed) {
                    ALSLog(ALLoggerSeverityError, @"Save failed will break from the for loop");
                    break;
                }

                ALChannelUserX *newChannelUserX = [[ALChannelUserX alloc] init];
                newChannelUserX.key = channel.key;
                if (channelUser.userId != nil) {
                    newChannelUserX.userKey = channelUser.userId;
                }
                if (channelUser.parentGroupKey != nil) {
                    newChannelUserX.parentKey = channelUser.parentGroupKey;
                }
                if (channelUser.role != nil) {
                    newChannelUserX.role = channelUser.role;
                }
                if (ALUserDefaultsHandler.isLoggedIn) {
                    [self.channelDBService createChannelUserXEntity:newChannelUserX  withContext:context];
                } else {
                    // User is not login will break from the inner loop.
                    break;
                }

                count++;
                if (count % AL_CHANNEL_MEMBER_BATCH_SIZE == 0) {
                    [databaseHandler saveWithContext:context completion:^(NSError *error) {

                        if (error) {
                            isProccessFailed = YES;
                        }
                    }];
                }
            }

            [databaseHandler saveWithContext:context completion:^(NSError *error) {
                NSString *operationStatus  = @"Save operation success";
                if (error) {
                    operationStatus = @"Save operation failed";
                }
                [self sendChannelSaveStatusNotification:operationStatus withChannel:channel];
                dispatch_group_leave(group);
            }];

        }];
        [self.channelDBService addedMembersArray:channel.membersName andChannelKey:channel.key];
        [self.channelDBService removedMembersArray:channel.removeMembers andChannelKey:channel.key];
        [self processChildGroups:channel];
    }

    dispatch_group_notify(group, dispatch_get_main_queue() , ^{
        NSDictionary *messageListInfo = isFromMessageList ? @{AL_MESSAGE_LIST: @YES} : @{AL_MESSAGE_SYNC: @YES};
        [[NSNotificationCenter defaultCenter] postNotificationName:AL_CHANNEL_MEMBER_CALL_COMPLETED object:nil userInfo:messageListInfo];
    });
}

- (void)sendChannelSaveStatusNotification:(NSString *)operationStatus withChannel:(ALChannel *)channel {
    [[NSNotificationCenter defaultCenter] postNotificationName:AL_Updated_Group_Members
                                                        object:channel
                                                      userInfo: @{AL_CHANNEL_MEMBER_SAVE_STATUS : operationStatus}];
}
- (void)createChannelsAndUpdateInfo:(NSMutableArray *)channelArray withDelegate:(id<ApplozicUpdatesDelegate>)delegate {

    for (ALChannel *channel in channelArray) {
        // Ignore inserting unread count in sync call
        channel.unreadCount = 0;
        [self createChannelEntry:channel fromMessageList:NO];
        if (delegate) {
            [delegate onChannelUpdated:channel];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Update_channel_Info" object:channel];
    }
}

#pragma mark - List of Channels where Login user in Channel

- (void)getListOfChannelWithCompletion:(void(^)(NSMutableArray *channelArray, NSError *error))completion {
    
    [self.channelClientService syncCallForChannel:[ALUserDefaultsHandler getChannelListLastSyncGeneratedTime] withFetchUserDetails:NO andCompletion:^(NSError *error, ALChannelSyncResponse *response) {
        if (error) {
            completion(nil, error);
            return;
        }
        [ALUserDefaultsHandler setChannelListLastSyncGeneratedTime:response.generatedAt];
        [self createChannelsAndUpdateInfo:response.alChannelArray withDelegate:nil];
        NSMutableArray *channelArray = [self getAllChannelList];
        completion(channelArray, nil);
    }];
}

@end
