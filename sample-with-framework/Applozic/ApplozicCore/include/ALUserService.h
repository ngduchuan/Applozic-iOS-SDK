//
//  ALUserService.h
//  Applozic
//
//  Created by Divjyot Singh on 05/11/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALConstant.h"
#import "ALSyncMessageFeed.h"
#import "ALMessageList.h"
#import "ALMessage.h"
#import "DB_FileMetaInfo.h"
#import "ALLastSeenSyncFeed.h"
#import "ALUserClientService.h"
#import "ALAPIResponse.h"
#import "ALUserBlockResponse.h"
#import "ALRealTimeUpdate.h"
#import "ALMuteRequest.h"
#import "ALChannelService.h"
#import "ALContactService.h"
#import "ALContactDBService.h"

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
/// @param messagesArr An Array of `ALMessage`.
/// @param completionMark The handler will be called once the competion is done.
- (void)processContactFromMessages:(NSArray *)messagesArr withCompletion:(void(^)(void))completionMark;

/// Fetching users whose last seen is updated recently.
/// @param lastSeenAt Pass the last getLastSeenSyncTime from ALUserDefaultsHandler.
/// @param completionMark In case of a successful fetch, it will have a list of ALUserDetail array. Otherwise, in case of failure, the error will not be nil.
- (void)getLastSeenUpdateForUsers:(NSNumber *)lastSeenAt withCompletion:(void(^)(NSMutableArray *))completionMark;

/// Fetching the user detail from server.
/// @param contactId Pass the userId for fetching.
/// @param completionMark Will have `ALUserDetail` in case of successfull fetch otherwise nil.
- (void)userDetailServerCall:(NSString *)contactId withCompletion:(void(^)(ALUserDetail *))completionMark;

/// Updating dispaly name of the user who is not registered.
/// @param alContact Pass the `ALContact` object.
- (void)updateUserDisplayName:(ALContact *)alContact;

/// Mark a conversation as read in a one-to-one chat.
/// @param contactId Pass the userId for marking conversation read.
/// @param completion In case of a successful conversation marked as read, the error will be nil. Otherwise, in case of failure, the error will not be nil.
- (void)markConversationAsRead:(NSString *)contactId withCompletion:(void (^)(NSString *, NSError *))completion;

/// Mark a single message as read using with given `ALMessage` object and paired message key from the `ALMessage` object.
/// @param alMessage An `ALMessage` object for marking the message as read.
/// @param pairedkeyValue An paired message key from the `ALMessage`object.
/// @param completion In case of a successful message marked as read, the error will be nil. Otherwise, an error describing mark conversation read failure.
- (void)markMessageAsRead:(ALMessage *)alMessage
    withPairedkeyValue:(NSString *)pairedkeyValue
      withCompletion:(void (^)(NSString *, NSError *))completion;

/// Used for blocking the user.
/// @param userId Pass the userId for blocking the user.
/// @param completion In case of any error in blocking, it will have an error in completion. Otherwise, if the block is successful it will have YES or true in userBlock.
- (void)blockUser:(NSString *)userId withCompletionHandler:(void(^)(NSError *error, BOOL userBlock))completion;

/// Fetching the blocked and unblocked user status.
/// @param lastSyncTime Pass the last sync time that synced before.
- (void)blockUserSync:(NSNumber *)lastSyncTime;

/// Used for unblocking the user.
/// @param userId Pass the userId that for unblocking the user.
/// @param completion In case of any error in unblocking it will have an error in completion. Otherwise, if unblock is successful, it will have YES or true in userUnblock.
- (void)unblockUser:(NSString *)userId
withCompletionHandler:(void(^)(NSError *error, BOOL userUnblock))completion;

/// Update the block status in local database.
/// @param userblock `ALUserBlockResponse` object parsing JSON.
- (void)updateBlockUserStatusToLocalDB:(ALUserBlockResponse *)userblock;

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
/// @param completion Array of an `ALUserDetail` object in case of successful fetch otherwise an error describing online user fetch failure.
- (void)fetchOnlineContactFromServer:(void(^)(NSMutableArray *array, NSError *error))completion;

/// Total unread count which are fetched from core database.
- (NSNumber *)getTotalUnreadCount;

/// Used for reseting the unread count.
/// @param completion Response JSON and Error in case of any error during reset.
/// @warning Will be removed in future updates.
- (void)resettingUnreadCountWithCompletion:(void (^)(NSString *json, NSError *error))completion;

/// Updating the display name, image URL, or status of a logged-in user in user.
/// @param displayName Pass the display name of a user.
/// @param imageLink Pass the image URL link of the user.
/// @param status Pass the status of the user.
/// @param completion If an error is not nil, the user detail will be fetched successfully, else error in the failure of fetching.
- (void)updateUserDisplayName:(NSString *)displayName
         andUserImage:(NSString *)imageLink
          userStatus:(NSString *)status
        withCompletion:(void (^)(id theJson, NSError *error))completion;

/// This method is used for fetching updated user details from the server.
/// @param userId Pass the userId for which the latest user detail is needed.
/// @param completionMark ALUserDetail in case of a successful fetch or else it will return nil in case of failure.
- (void)updateUserDetail:(NSString *)userId withCompletion:(void(^)(ALUserDetail *userDetail))completionMark;

/// This method is used for updating the phone number, emailId based on ofUserID on the behalf of the user the admin can edit the details.
/// @param phoneNumber Pass the phone number if update required otherwise pass nil.
/// @param email Pass the Email ID if update required otherwise pass nil.
/// @param userId Pass the userId on the behalf update required.
/// @param completion YES in case of update success otherwise NO in case of any error.
- (void)updateUser:(NSString *)phoneNumber
       email:(NSString *)email
      ofUser:(NSString *)userId
  withCompletion:(void (^)(BOOL))completion;

/// This method is used for fetching user details by passing an array of users.
/// @param userArray Add the userIds and pass it an array for user details.
/// @param completion Array of ALUserDetail in case of a successful fetch or else it will return NSError in case of failure.
- (void)fetchAndupdateUserDetails:(NSMutableArray *)userArray withCompletion:(void (^)(NSMutableArray *array, NSError *error))completion;

/// This method is used for fetching contact or user details. If a contact exists in the database, it will return from a database, or else it will fetch details from the server and return it.
/// @param userId Pass the userId for fetching user details.
/// @param completion ALContact on fetch completion.
- (void)getUserDetail:(NSString*)userId withCompletion:(void(^)(ALContact *contact))completion;

/// This method is used for update a logged-in user password to new one.
/// @param oldPassword Pass the existing password of the user.
/// @param newPassword Pass new password of the user.
/// @param completion ALAPIResponse` in status of this it will have success fetched the data successfully or error in case of any error.
- (void)updatePassword:(NSString *)oldPassword
    withNewPassword:(NSString *)newPassword
    withCompletion:(void(^)(ALAPIResponse *alAPIResponse, NSError *theError))completion;

/// This method is used for resetting the unread count.
/// @warning This method will be removed in future updates.
- (void)processResettingUnreadCount;

/// This method is used for searching the user based on the name of the user.
/// @param userName Pass the name of the user to search
/// @param completion `ALAPIResponse` in the status of this it will have success fetched the data successfully or error in case of any error.
- (void)getListOfUsersWithUserName:(NSString *)userName withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

/// This method will post the conversation read status with notification name `Update_unread_count` and userInfo will have the userId of the user whose conversation has been read from another platform.
/// @param userId of user that notification to post for read.
/// @param delegate `ApplozicUpdatesDelegate` for sending callback for read conversation.
/// @warning This method is used internal for posting notification.
- (void)updateConversationReadWithUserId:(NSString *)userId withDelegate:(id<ApplozicUpdatesDelegate>)delegate;

/// This method will fetch the muted users from an Applozic server.
/// @param delegate If ApplozicUpdatesDelegate is passed, the event for onUserMuteStatus will be called.
/// @param completion Array of ALUserDetail in case of a successful fetch or else it will return NSError in case of failure.
- (void)getMutedUserListWithDelegate:(id<ApplozicUpdatesDelegate>)delegate
           withCompletion:(void(^)(NSMutableArray *userDetailArray, NSError *error))completion;

/// This method is used for to mute a user in one to one chat.
/// @param alMuteRequest Pass the ALMuteRequest object for the userId and notificationAfterTime.
/// @param completion ALAPIResponse in case of a successful update or else it will return NSError in case of failure.
- (void)muteUser:(ALMuteRequest *)alMuteRequest withCompletion:(void(^)(ALAPIResponse *response, NSError *error))completion;

/// This method used for reporting the message to the admin of the account
/// @param messageKey Pass message key of message object
/// @param completion ALAPIResponse response callback if success or error and NSError if any error occurs
- (void)reportUserWithMessageKey:(NSString *)messageKey withCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

/// Used for disable the chat.
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

/// Gets the registered contacts from Applozic server and contacts from local database.
/// @param nextPage If nextPage is NO or false, it will get contacts from starting and return the array of contact.
/// If nextPage The flag is YES or true, it will return the next older contacts.
/// @param completion Array of ALContact in case of successfully fetched, else it will return NSError.
- (void)getListOfRegisteredContactsWithNextPage:(BOOL)nextPage
                 withCompletion:(void(^)(NSMutableArray *contactArray, NSError *error))completion;

/// Mark the conversation as read in local core data base.
/// @param alMessage Pass the `ALMessage` object.
- (void)markConversationReadInDataBaseWithMessage:(ALMessage *)alMessage;

@end
