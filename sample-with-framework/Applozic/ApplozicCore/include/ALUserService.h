//
//  ALUserService.h
//  Applozic
//
//  Created by Divjyot Singh on 05/11/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import "ALChannelService.h"
#import "ALConstant.h"
#import "ALContactDBService.h"
#import "ALContactService.h"
#import "ALLastSeenSyncFeed.h"
#import "ALMessage.h"
#import "ALMessageList.h"
#import "ALMuteRequest.h"
#import "ALRealTimeUpdate.h"
#import "ALSyncMessageFeed.h"
#import "ALUserBlockResponse.h"
#import "ALUserClientService.h"
#import "DB_FileMetaInfo.h"
#import <Foundation/Foundation.h>

/// `ALUserService` has a Applozic user APIs.
///
/// Some of the methods that this class has:
///
/// * User details fetch.
/// * Mark conversation for one-to-one chat.
/// * Update user details to Applozic server.
/// * Report user message.
/// * List of Registered contacts or users in Applozic Server.
/// * Update user display who is not logged-in in Applozic server.
@interface ALUserService : NSObject

/// Instance method of `ALUserService`
+ (ALUserService *)sharedInstance;

/// Instance method of `ALUserClientService`
@property (nonatomic, strong) ALUserClientService *userClientService;

/// Instance method of `ALChannelService`
@property (nonatomic, strong) ALChannelService *channelService;

/// Instance method of `ALContactDBService`
@property (nonatomic, strong) ALContactDBService *contactDBService;

/// Instance method of `ALContactService`
@property (nonatomic, strong) ALContactService *contactService;

/// Fetching user details based on the `ALMessage` array.
/// @param messages An Array of `ALMessage` object.
/// @param completionMark The handler will be called once the competion is done.
- (void)processContactFromMessages:(NSArray *)messages withCompletion:(void(^)(void))completionMark;

/// Fetching users whose last seen is updated recently.
/// @param lastSeenAtTime Pass the last getLastSeenSyncTime from ALUserDefaultsHandler.
/// @param completionMark In case of a successful fetch, it will have a list of `ALUserDetail` array. Otherwise, in case of failure, the error will not be nil.
- (void)getLastSeenUpdateForUsers:(NSNumber *)lastSeenAtTime withCompletion:(void(^)(NSMutableArray *userDetailArray))completionMark;

/// Mark a conversation as read in a one-to-one chat.
/// @param userId Pass the userId for marking conversation read.
/// @param completion In case of a successful conversation marked as read, the error will be nil. Otherwise, in case of failure, the error will not be nil.
- (void)markConversationAsRead:(NSString *)userId withCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion;

/// Mark a single message as read using with given `ALMessage` object and paired message key from the `ALMessage` object.
/// @param message An `ALMessage` object for marking the message as read.
/// @param pairedkeyValue An paired message key from the `ALMessage` object.
/// @param completion In case of a successful message marked as read, the error will be nil. Otherwise, an error describing mark conversation read failure.
- (void)markMessageAsRead:(ALMessage *)message
       withPairedkeyValue:(NSString *)pairedkeyValue
           withCompletion:(void (^)(NSString *, NSError *))completion;

/// Used for blocking the user.
/// @param userId Pass the userId for blocking the user.
/// @param completion In case of any error in blocking, it will have an error in completion. Otherwise, if the block is successful it will have YES or true in userBlock.
- (void)blockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL hasUserBlocked))completion;

/// Fetching the blocked and unblocked user status.
/// @param lastSyncTime Pass the last sync time that synced before.
- (void)blockUserSync:(NSNumber *)lastSyncTime;

/// Used for unblocking the user.
/// @param userId Pass the userId that for unblocking the user.
/// @param completion In case of any error in unblocking it will have an error in completion. Otherwise, if unblock is successful, it will have YES or true in userUnblock.
- (void)unblockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL hasUserUnblocked))completion;

/// Update the block status in local database.
/// @param userBlockResponse An `ALUserBlockResponse` object parsing JSON.
/// @warning Method is used for Internal use only.
- (void)updateBlockUserStatusToLocalDB:(ALUserBlockResponse *)userBlockResponse;

/// Returns array of userIds which are blocked by logged-in user.
- (NSMutableArray *)getListOfBlockedUserByCurrentUser;

/// Used for set unread count to zero in local database.
/// @param contactId Receiver userId to reset the count to zero.
- (void)setUnreadCountZeroForContactId:(NSString *)contactId;

/// Fetching registered users in your App-ID.
///
/// On completion you can fetch the users from `ALContactDBService` method `getAllContactsFromDB`.
/// @param completion An error describing registered user failure otherwise it will be nil in case of success.
- (void)getListOfRegisteredUsersWithCompletion:(void(^)(NSError *error))completion;

/// Fetching a list of top online users based on the `onlineContactLimit` from `ALApplozicSettings`.
/// @param completion Array of an `ALContact` object in case of successful fetch otherwise an error describing online user fetch failure.
- (void)fetchOnlineContactFromServer:(void(^)(NSMutableArray *contactArray, NSError *error))completion;

/// Total unread count which are fetched from core database.
- (NSNumber *)getTotalUnreadCount;

/// Updating the display name, image URL, or status of a logged-in user in user.
/// @param displayName Pass the display name of a user.
/// @param imageLink Pass the image URL link of the user.
/// @param status Pass the status of the user.
/// @param completion If an error is not nil, the user detail will be fetched successfully, else error in the failure of fetching.
- (void)updateUserDisplayName:(NSString *)displayName
                 andUserImage:(NSString *)imageLink
                   userStatus:(NSString *)status
               withCompletion:(void (^)(id jsonResponse, NSError *error))completion;

/// Used for fetching updated user details from the server.
/// @param userId Pass the userId for which the latest user detail is needed.
/// @param completionMark ALUserDetail in case of a successful fetch or else it will return nil in case of failure.
- (void)updateUserDetail:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark;

/// Updates user details like the phone number, emailId based on ofUserID on the behalf of the user the admin can edit the details.
///
/// @param phoneNumber Pass the phone number if update required otherwise pass nil.
/// @param email Pass the Email ID if update required otherwise pass nil.
/// @param userId Pass the userId on the behalf update required.
/// @param completion YES in case of update success otherwise NO in case of any error.
/// @warning Used only for internal purpose only.
- (void)updateUser:(NSString *)phoneNumber
             email:(NSString *)email
            ofUser:(NSString *)userId
    withCompletion:(void (^)(BOOL))completion;

/// Gets array of `ALUserDetail` for given array of userIds.
/// @param userArray Add the userIds and pass it an array for user details.
/// @param completion Array of ALUserDetail in case of a successful fetch or else it will return NSError in case of failure.
- (void)getUserDetails:(NSMutableArray *)userArray
        withCompletion:(void (^)(NSMutableArray *userDetailArray, NSError *error))completion;

/// Gets `ALContact` object if exists in server otherwise, creates contact for given userId in local database and returns.
/// @param userId Pass the userId for fetching user details.
/// @param completion `ALContact` on fetch completion.
- (void)getUserDetail:(NSString *)userId withCompletion:(void(^)(ALContact *contact))completion;

/// This method is used for update a logged-in user password to new one.
/// @param oldPassword Pass the existing password of the user.
/// @param newPassword Pass new password of the user.
/// @param completion ALAPIResponse` in status of this it will have success fetched the data successfully or error in case of any error.
- (void)updatePassword:(NSString *)oldPassword
       withNewPassword:(NSString *)newPassword
        withCompletion:(void(^)(ALAPIResponse *apiResponse, NSError *error))completion;

/// Search the users for given name of user.
/// @param userName Pass the name of the user to search
/// @param completion `ALAPIResponse` in the status of this it will have success fetched the data successfully or error in case of any error.
- (void)getListOfUsersWithUserName:(NSString *)userName withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

/// Posts the conversation read status with notification name `Update_unread_count` and userInfo will have the userId of the user whose conversation has been read from another platform.
/// @param userId of user that notification to post for read.
/// @param delegate `ApplozicUpdatesDelegate` for sending callback for read conversation.
/// @warning This method is used internal purpose only for posting notification.
- (void)updateConversationReadWithUserId:(NSString *)userId withDelegate:(id<ApplozicUpdatesDelegate>)delegate;

/// Gets the muted users from an Applozic server.
/// @param delegate If ApplozicUpdatesDelegate is passed, the event for onUserMuteStatus will be called.
/// @param completion Array of ALUserDetail in case of a successful fetch or else it will return NSError in case of failure.
- (void)getMutedUserListWithDelegate:(id<ApplozicUpdatesDelegate>)delegate
                      withCompletion:(void(^)(NSMutableArray *userDetailArray, NSError *error))completion;

/// Used for mute a user in one-to-one chat.
/// @param muteRequest Pass the ALMuteRequest object for the userId and notificationAfterTime.
/// @param completion ALAPIResponse in case of a successful update or else it will return NSError in case of failure.
- (void)muteUser:(ALMuteRequest *)muteRequest withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

/// Used for reporting the message to the admin of the account
/// @param messageKey Pass message key of `ALMessage` object
/// @param completion ALAPIResponse response callback if success or error and NSError if any error occurs
- (void)reportUserWithMessageKey:(NSString *)messageKey withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

/// Used for disable the chat for logged in user in all conversations.
/// @param disable Pass YES for disabling the chat otherwise NO for enable.
/// @param completion Response is YES then disabled successfully otherwise error.
- (void)disableChat:(BOOL)disable withCompletion:(void(^)(BOOL response, NSError *error)) completion;

/// Updating the display name of a user who is not registered or does not login to an Applozic server for given receiver userId and user name.
/// @param userId Pass the receiver userId.
/// @param displayName Pass the user display name of the receiver.
/// @param completion ALAPIResponse in case of a successful update or else it will return NSError in case of failure.
- (void)updateDisplayNameWith:(NSString *)userId
              withDisplayName:(NSString *)displayName
               withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

/// Gets the registered contacts from Applozic server and from local database.
/// @param nextPage If nextPage is NO or false, it will get contacts from starting and return the array of contact.
/// If nextPage the flag is YES or true, it will return the next older contacts.
/// @param completion Array of ALContact in case of successfully fetched, else it will return NSError.
- (void)getListOfRegisteredContactsWithNextPage:(BOOL)nextPage
                                 withCompletion:(void(^)(NSMutableArray *contactArray, NSError *error))completion;

/// Mark the conversation as read in local core database for given message.
/// Method is used for Internal use only.
/// @param message Pass the `ALMessage` object.
- (void)markConversationReadInDataBaseWithMessage:(ALMessage *)message;

/// Gets the user `ALContact` object for given userId from Applozic server.
///
/// @param userId An receiver userId to fetch the details.
/// @param completion An `ALContact` object on successful fetch otherwise, an error describing fetch user details.
- (void)getUserDetailFromServer:(NSString *)userId
                 withCompletion:(void(^)(ALContact *contact, NSError *error))completion;

/// Fetching the user detail from server.
/// @param userId Pass the userId for fetching.
/// @param completionMark Will have `ALUserDetail` in case of successfull fetch otherwise nil.
- (void)userDetailServerCall:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark DEPRECATED_MSG_ATTRIBUTE("Use getUserDetailFromServer:withCompletion instead");

/// Updates dispaly name of the user who is not registered.
/// @param contact Pass the `ALContact` object.
- (void)updateUserDisplayName:(ALContact *)contact DEPRECATED_ATTRIBUTE;

/// This method is used for resetting the unread count.
/// @warning This method will be removed in future updates.
- (void)processResettingUnreadCount DEPRECATED_ATTRIBUTE;

/// Used for reseting the unread count.
/// @param completion Response JSON and Error in case of any error during reset.
/// @warning Will be removed in future updates.
- (void)resettingUnreadCountWithCompletion:(void (^)(NSString *jsonResponse, NSError *error))completion DEPRECATED_ATTRIBUTE;

@end
