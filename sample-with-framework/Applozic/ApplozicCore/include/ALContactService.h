//
//  ALContactService.h
//  ChatApp
//
//  Created by Devashish on 23/10/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALContact.h"
#import "DB_CONTACT.h"
#import "ALUserDetail.h"
#import "ALContactDBService.h"

/// `ALContactService` class used for adding, fetching, updating, deleting `ALContact` or user details.
@interface ALContactService : NSObject

/// Instance method of `ALContactDBService`.
@property (nonatomic, strong) ALContactDBService *alContactDBService;

/// This method is used for deleting array of contacts.
/// @param contacts Pass the array of `ALContact` objects for deleting.
- (BOOL)purgeListOfContacts:(NSArray *)contacts;

/// This method will delete the contact from local database.
/// @param contact Pass the contact for deleting.
- (BOOL)purgeContact:(ALContact *)contact;

/// This will delete all the contacts from core database.
- (BOOL)purgeAllContact;

/// This method is used for updating an array of contacts in the local database.
/// @param contacts Pass the array of `ALContact` objects for updating.
- (BOOL)updateListOfContacts:(NSArray *)contacts;

/// This method is used for updating the contact in the local database.
/// @param contact Pass the `ALContact` object to update.
- (BOOL)updateContact:(ALContact *)contact;

/// This method is used for adding an array of contacts in a local database.
/// @param contacts Pass the array of `ALContact` to add.
- (BOOL)addListOfContacts:(NSArray *)contacts;

/// This method is used for adding the contact in the local database.
/// @param userContact Create a `ALContact` object and set up the details and pass it to the method.
- (BOOL)addContact:(ALContact *)userContact;

/// This method is used for loading the contact or user detail from the local database.
/// If the contact does not exist, it will create a contact object and return ALContact.
/// @param key Pass on which detail should be fetched on the bases.
/// Ex: to fetch based on the userId key, then pass the string as userId.
/// @param value Pass the value of the userId of the user to get the details.
/// @return Returns a `ALContact` object.
- (ALContact *)loadContactByKey:(NSString *)key value:(NSString *)value;

/// This method is used loading the contact from local database if contact exist otherwise it will create new contact with userId and display name.
/// @param contactId Pass the userId of the reciever.
/// @param displayName Pass the display name of the user.
/// @return Returns a `ALContact` object.
- (ALContact *)loadOrAddContactByKeyWithDisplayName:(NSString *)contactId value:(NSString *)displayName;

/// This method is used for setting the unread count in contact.
/// @param contact Pass the `ALContact` object.
- (BOOL)setUnreadCountInDB:(ALContact *)contact;

/// This method is used for getting total unread count of all the contacts or user.
- (NSNumber *)getOverallUnreadCountForContact;

/// This method is used for checking if the contact or user exists in the locally stored database.
/// @param value Pass the userId of the user for checking if the contact exists in the database.
- (BOOL)isContactExist:(NSString *)value;

/// This method is used for updating local contact or adding a new contact if contact does not exist in the local database.
/// @param contact Pass the `ALContact` object with details to update or insert the contact.
- (BOOL)updateOrInsert:(ALContact *)contact;

/// This method is used for updating local contact or adding a new contact if contact does not exist in the local database.
/// @param contacts Pass the array of `ALContact` object with details to update or insert the contact.
- (void)updateOrInsertListOfContacts:(NSMutableArray *)contacts;

/// This method is used for checking if the user is deleted. This will check from the local database which is stored not from the server.
/// @param userId Pass the userId of the user to check whether the user is deleted or not.
- (BOOL)isUserDeleted:(NSString *)userId;

/// This method is used for updating mute time in local database.
/// @param notificationAfterTime Time in milliseconds.
/// @param userId Pass the userId for updating time stamp in database.
- (ALUserDetail *)updateMuteAfterTime:(NSNumber *)notificationAfterTime andUserId:(NSString *)userId;
@end
