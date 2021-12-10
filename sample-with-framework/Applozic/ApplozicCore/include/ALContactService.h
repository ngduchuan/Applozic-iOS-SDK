//
//  ALContactService.h
//  ChatApp
//
//  Created by Devashish on 23/10/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALContact.h"
#import "ALContactsResponse.h"
#import "ALContactDBService.h"
#import "ALRealTimeUpdate.h"
#import "ALUserBlocked.h"
#import "ALUserDetail.h"
#import "DB_CONTACT.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALContactService` class used for adding, fetching, updating, deleting `ALContact` or user details.
@interface ALContactService : NSObject

/// Instance method of `ALContactDBService`.
@property (nonatomic, strong) ALContactDBService *alContactDBService;

/// Deletes array of contacts from local database.
/// @param contacts Pass the array of `ALContact` objects for deleting.
- (BOOL)purgeListOfContacts:(NSArray *)contacts;

/// Delete the contact from local database.
/// @param contact Pass the contact for deleting.
- (BOOL)purgeContact:(ALContact *)contact;

/// Deletes all contacts from core database.
- (BOOL)purgeAllContact;

/// Updates an array of contacts in the local database.
/// @param contacts Pass the array of `ALContact` objects for updating.
- (BOOL)updateListOfContacts:(NSArray *)contacts;

/// Updates the contact in the local database.
/// @param contact Pass the `ALContact` object to update.
- (BOOL)updateContact:(ALContact *)contact;

/// Adds an array of contacts in a local database.
/// @param contacts Pass the array of `ALContact` to add.
- (BOOL)addListOfContacts:(NSArray *)contacts;

/// Adds the contact in the local database.
/// @param userContact Create a `ALContact` object and set up the details and pass it to the method.
- (BOOL)addContact:(ALContact *)userContact;

/// This method is used for loading the contact or user detail from the local database.
/// If the contact does not exist, it will create a contact object and return ALContact.
/// @param key Pass on which detail should be fetched on the bases.
/// Ex: to fetch based on the userId key, then pass the string as userId.
/// @param value Pass the value of the userId of the user to get the details.
/// @return Returns a `ALContact` object.
- (ALContact * _Nullable)loadContactByKey:(NSString *)key value:(NSString *)value;

/// Gets the contact from local database if contact exist otherwise it will create new contact with userId and display name.
/// @param contactId Pass the userId of the reciever.
/// @param displayName Pass the display name of the user.
/// @return Returns a `ALContact` object.
- (ALContact *)loadOrAddContactByKeyWithDisplayName:(NSString *)contactId value:(NSString *)displayName;

/// Sets the unread count in contact.
/// @param contact Pass the `ALContact` object.
- (BOOL)setUnreadCountInDB:(ALContact *)contact;

/// Gets the total unread count of all the contacts or user.
- (NSNumber * _Nullable)getOverallUnreadCountForContact;

/// Returns YES if contact exist otherwise NO.
/// @param userId Pass the userId of the user for checking if the contact exists in the database.
- (BOOL)isContactExist:(NSString *)userId;

/// Updates or adds a new contact in the local database.
/// @param contact Pass the `ALContact` object with details to update or insert the contact.
- (BOOL)updateOrInsert:(ALContact *)contact;

/// Updates or adds a array of contacts in the local database.
/// @param contacts Pass the array of `ALContact` object with details to update or insert the contact.
- (void)updateOrInsertListOfContacts:(NSMutableArray *)contacts;

/// Used for checking if the user is deleted. This will check from the local database which is stored not from the server.
/// @param userId Pass the userId of the user to check whether the user is deleted or not.
- (BOOL)isUserDeleted:(NSString *)userId;

/// Updates user mute time in local database.
/// @param notificationAfterTime Time in milliseconds.
/// @param userId Pass the userId for updating time stamp in database.
- (ALUserDetail * _Nullable)updateMuteAfterTime:(NSNumber *)notificationAfterTime andUserId:(NSString *)userId;
@end

NS_ASSUME_NONNULL_END
