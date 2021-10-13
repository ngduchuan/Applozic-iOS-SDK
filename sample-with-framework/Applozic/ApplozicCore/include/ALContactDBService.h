//
//  ALContactDBService.h
//  ChatApp
//
//  Created by Devashish on 23/10/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALContact.h"
#import "ALContactsResponse.h"
#import "ALRealTimeUpdate.h"
#import "ALUserBlocked.h"
#import "ALUserDetail.h"
#import "DB_CONTACT.h"
#import <Foundation/Foundation.h>

/// `ALContactDBService` class used for adding, fetching, updating, deleting `ALContact` or User details and this class is called from `ALContactService` class.
@interface ALContactDBService : NSObject

/// Deletes array of contacts from local database.
/// @param contacts Pass the array of `ALContact` objects for deleting.
- (BOOL)purgeListOfContacts:(NSArray *)contacts;

/// Delete the contact from local database.
/// @param contact Pass the `ALContact` for deleting.
- (BOOL)purgeContact:(ALContact *)contact;

/// Deletes all contacts from core database.
- (BOOL)purgeAllContact;

/// Updates an array of contacts in the local database.
/// @param contacts Pass the array of `ALContact `objects.
- (BOOL)updateListOfContacts:(NSArray *)contacts;

/// Updates the contact in the local database.
/// @param contact Pass the array of `ALContact` objects.
- (BOOL)updateContactInDatabase:(ALContact *)contact;

/// Adds an array of contacts in a local database.
/// @param contacts Pass the array of `ALContact` to add.
- (BOOL)addListOfContacts:(NSArray *)contacts;

/// Adds the contact in the local database.
/// @param userContact Create a `ALContact` object and set up the details and pass it to the method.
- (BOOL)addContactInDatabase:(ALContact *)userContact;

/// Updates a connected status.
/// @param userId Pass the userId of the user.
/// @param lastSeenAt Pass the last seen at time stamp.
/// @param connected Pass the connected status.
- (void)updateConnectedStatus:(NSString *)userId lastSeenAt:(NSNumber *)lastSeenAt connected:(BOOL)connected;

/// Gets the `DB_CONTACT` object from local database.
/// @param key Pass the key for fecthing contact
/// Example : For searching using key userId the key can be `userId`.
/// @param value Pass the userId string to fetching.
/// @return Returns a `DB_CONTACT` object.
- (DB_CONTACT *)getContactByKey:(NSString *)key value:(NSString *)value;

/// This method is used for loading the contact or user detail from the local database.
/// If the contact does not exist, it will create a contact object and return ALContact.
/// @param key Pass on which detail should be fetched on the bases.
/// Ex: to fetch based on the userId key, then pass the string as userId.
/// @param value Pass the value of the userId of the user to get the details.
/// @return Returns a `ALContact` object.
- (ALContact *)loadContactByKey:(NSString *)key value:(NSString *)value;

/// Adds user details in local database.
/// @param userDetails Pass array of `ALUserDetail`.
- (void)addUserDetails:(NSMutableArray *)userDetails;

/// Updates `ALUserDetail` object local database.
/// @param userDetail Pass the `ALUserDetail` object with details.
- (BOOL)updateUserDetail:(ALUserDetail *)userDetail;

/// Updates last seen status of user in local database.
/// @param userDetail Pass the `ALUserDetail` object with details.
- (BOOL)updateLastSeenDBUpdate:(ALUserDetail *)userDetail;

/// Marks a conversation as delivered and read in local database.
/// @param contactId Pass the userId for marking conversation Delivered and Read.
- (NSUInteger)markConversationAsDeliveredAndRead:(NSString *)contactId;

/// This an internal method used for getting unread messages
/// @param contactId Pass the userId of the User.
- (NSArray *)getUnreadMessagesForIndividual:(NSString *)contactId;

/// Sets the blocked status for user in local database.
/// @param userId Pass the userId of reciever that is blocked or unblocked.
/// @param flag Pass YES in case you blocked the user otherwise Pass NO in case of unblocked.
- (BOOL)setBlockUser:(NSString *)userId andBlockedState:(BOOL)flag;

/// Sets the reciever blocked to you.
/// @param userId Pass the userId of the user who blocked or unblocked you.
/// @param flag Pass YES in case you blocked the user otherwise Pass NO in case of unblocked.
- (BOOL)setBlockByUser:(NSString *)userId andBlockedByState:(BOOL)flag;

/// Used for storing array of users you block and it has array of  `ALUserBlocked` object.
/// @param userList Pass the Array of `ALUserBlocked` object.
- (void)blockAllUserInList:(NSMutableArray *)userList;

/// Used for storing array of users who blocked you and it has array of  `ALUserBlocked` object.
/// @param userList Pass the Array of `ALUserBlocked` object.
- (void)blockByUserInList:(NSMutableArray *)userList;

/// Gets a array of block users.
- (NSMutableArray *)getListOfBlockedUsers;

/// Used for setting unread count.
/// @param contact Pass the `ALContact` for user to set the unread count.
- (BOOL)setUnreadCountDB:(ALContact *)contact;

/// Adds or updates contact details.
/// @param contactsResponse Pass the `ALContactsResponse` object for storing in local database.
/// @param isLoadContactFromDb Pass YES in case of loading the contact from local database otherwise pass NO in case of Empty return array.
- (NSMutableArray *)updateFilteredContacts:(ALContactsResponse *)contactsResponse withLoadContact:(BOOL)isLoadContactFromDb;

/// Gets all the contacts from the local database and this will have array of `ALContact` objects.
- (NSMutableArray *)getAllContactsFromDB;

/// Used for get the total unread count of all users.
- (NSNumber *)getOverallUnreadCountForContactsFromDB;

/// Used for checking if the user is deleted. This will check from the local database which is stored not from the server.
/// @param userId Pass the userId of the user to check whether the user is deleted or not.
- (BOOL)isUserDeleted:(NSString *)userId;

/// Used for adding user details of `ALUserDetail` object without the unreadcount.
/// @param userDetails Array of `ALUserDetail` objects
- (void)addUserDetailsWithoutUnreadCount:(NSMutableArray *)userDetails;

/// Used for updating mute time in local database.
/// @param notificationAfterTime Time in milliseconds.
/// @param userId Pass the userId for updating time stamp.
/// @return Returns a `ALUserDetail` object.
- (ALUserDetail *)updateMuteAfterTime:(NSNumber *)notificationAfterTime andUserId:(NSString *)userId;

/// Internal method is used adding or updating the Array of type `ALUserDetail` .
/// @param delegate Pass the `ApplozicUpdatesDelegate` for user mute status update callback.
/// @param jsonNSDictionary Pass the JSON Dictionary of `ALUserDetail` object.
- (NSMutableArray *)addMuteUserDetailsWithDelegate:(id<ApplozicUpdatesDelegate>)delegate withNSDictionary:(NSDictionary *)jsonNSDictionary;

/// Used for updating or adding user matadata in local database.
/// @param userId Pass the userId of the user for storing the metadata,
/// @param key key Pass the key of the metadata to add or update.
/// @param value Pass the value of the metadata for the metadata key.
- (BOOL)addOrUpdateMetadataWithUserId:(NSString *)userId withMetadataKey:(NSString *)key withMetadataValue:(NSString *)value;
@end
