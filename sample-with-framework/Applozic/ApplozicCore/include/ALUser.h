//
//  ALUser.h
//  ChatApp
//
//  Created by devashish on 18/09/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ALJson.h"

/// Used to tell the backend what kind of authentication the user wishes to use to be authenticated. See the types for details.
typedef enum
{
    /// Tells Applozic that you will handle authentication yourself using `password` and [this](https://docs.applozic.com/docs/access-token-url) tells you how to implement your authentication.
    CLIENT = 0,
    /// Tells Applozic to handle the authentication itself. Use this if you do not know what you should be using.
    APPLOZIC = 1,
    /// Deprecated will be removed in next updates.
    FACEBOOK DEPRECATED_ATTRIBUTE = 2,
} AuthenticationType;

/// APNs types are deprecated will be removed in the future.
typedef enum
{
    AL_DEVELOPMENT DEPRECATED_ATTRIBUTE = 0,
    AL_DISTRIBUTION DEPRECATED_ATTRIBUTE = 1,
} deviceApnsType DEPRECATED_ATTRIBUTE;

/// `ALUser` is an authenticated entity that can use chat functionality.
///
/// A user is identified by its `userId` which is unique for an `applicationId`.
///
/// When creating an user you need to set the fields `userId`, `authenticationTypeId`
/// user is can register or login using `-[ALRegisterUserClientService initWithCompletion:withCompletion:]` or `-[ApplozicClient loginUser:withCompletion:]` method.
///
/// - SeeAlso : `ALContact`
@interface ALUser : ALJson

/// An unique userId to login to applozic server.
/// @note +,*,? are not allowed chars in userId.
@property NSString *userId;

/// :nodoc:
@property NSString *email;

/// :nodoc:
@property NSString *password;

/// Sets the user name.
@property NSString *displayName;

/// An APN's or VOIP device token.
@property NSString *registrationId;

/// Applozic APP-ID you can get it from [console](https://console.applozic.com/login).
@property NSString *applicationId;

/// User contact number.
@property NSString *contactNumber;

/// Sets the code of the country in which the user resides.
@property NSString *countryCode;

/// :nodoc:
@property short prefContactAPI;

/// Sets the email verified for this user.
@property Boolean emailVerified;

/// :nodoc:
@property NSString *timezone;

/// For internal use only.
@property short appVersionCode;

/// Roles give your user certain privileges.
@property NSString *roleName;

/// Sets the device type for identifying on the applozic server.
///
/// The types of devices and their values are:
/// WEB = 0,
/// ANDROID = 1,
/// IOS = 4
@property short deviceType;

/// User profile image URL.
@property NSString *imageLink;

/// App module name is used when two different apps are communicating with different app modules and the same APP-ID.
///
/// Use this settings `[ALUserDefaultsHandler setAppModuleName:@"NAME-OF-MODULE-HERE"];` to pass the module name`.
/// @note This is set internally not required to set using appModuleName.
@property NSString *appModuleName;

/// To identify the user type.
/// @note This is not used currently will be removed in future.
@property short userTypeId;

/// Internally sets the notification mode.
///
/// Use the method `[ALUserDefaultsHandler setNotificationMode:BELOW-TyPE];` to set the notification mode :
/// AL_NOTIFICATION_ENABLE = 0,
/// AL_NOTIFICATION_DISABLE_SOUND = 1,
/// AL_NOTIFICATION_DISABLE = 2
@property short notificationMode;

/// Used to tell the backend what kind of authentication the user wishes to use to be authenticated see the `AuthenticationType`.
@property short authenticationTypeId;

/// App unread badge count.
///
/// Types: 0: For disable badge count, 1: For enable badge count.
@property short unreadCountType;

/// For identifying the current user login from Debug or Release mode for sending APNs notification based on this.
/// @note This is set internally not required to set.
@property short deviceApnsType;

/// :nodoc:
@property short pushNotificationFormat;

/// Enables the message encryption user.
@property BOOL enableEncryption;

/// :nodoc:
@property NSNumber *contactType;

/// Sets the added features that Applozic provides.
///
/// Features are functionalities that are advanced enough to require added set up for them to work.
/// In the case of "100" audio calls and "101" video calls you will need to use `ApplozicAudioVideo` Call SDK that works with the Chat SDK.
@property NSMutableArray *features;

/// APN's message notification sound name.
@property NSString *notificationSoundFileName;

/// Extra information can be stored in the user.
///
/// Example: Use the below code to set the metadata
///
/// @code
///
/// // User metadata dictionary
/// NSMutableDictionary *userMetaData = [[NSMutableDictionary alloc] init];
/// [userMetaData setValue:@"Software engineer" forKey:@"designation"];
/// [userMetaData setValue:@"Bengaluru" forKey:@"city"];
/// [userMetaData setValue:@"India" forKey:@"country"];
///
/// // Set the metadata in `ALUser` object
/// [user setMetadata:userMetaData];
///
/// @endcode
@property NSMutableDictionary *metadata;

/// Get an `ALUser` object with given userId, password, email and display name of user.
/// @param userId An unique userId to login to applozic server.
/// @param password User password/access token.
/// @param email Email id of the user.
/// @param displayName Name of the user to show in chat conversation.
- (instancetype)initWithUserId:(NSString *)userId
                      password:(NSString *)password
                         email:(NSString *)email
                andDisplayName:(NSString *)displayName;

@end
