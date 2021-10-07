//
//  ALRegisterUserClientService.h
//  ChatApp
//
//  Created by devashish on 18/09/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//
#import "ALAPIResponse.h"
#import "ALConstant.h"
#import <Foundation/Foundation.h>
#import "ALRegistrationResponse.h"
#import "ALResponseHandler.h"
#import "ALUser.h"

/// For internal use only.
static short AL_VERSION_CODE = 112;

/// `ALRegisterUserClientService` used for registration and authentication of the user.
///
/// Basic methods it has :
///
/// * APN's or VOIP device token update to Applozic server,
/// * Update notification modes.
/// * Sync account status of Application.
/// * Logout user.
@interface ALRegisterUserClientService : NSObject

/// `ALResponseHandler` instance method is used for actual request call to API's. Default instance is created from `init` method of `ALRegisterUserClientService`.
@property (nonatomic, strong) ALResponseHandler *responseHandler;

/// Use this method to log in or register your `ALUser`. This must be done before any other method of the SDK is used.
///
/// @param user An `ALUser` object details for identifying the user on the server.
/// @param completion An ALAPIResponse will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the login failure
- (void)initWithCompletion:(ALUser *)user withCompletion:(void(^)(ALRegistrationResponse *message, NSError *error)) completion;

/// Updates an APNs device token to Applozic server for real-time updates on messages and other events to the device.
///
/// APN's device token which is generated from `didRegisterForRemoteNotificationsWithDeviceToken` method of `UIApplicationDelegate` in your AppDelegate file.
/// @param apnDeviceToken APN's device token is used for sending an APNs push notifications to iPhone device.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the logout failure.
- (void)updateApnDeviceTokenWithCompletion:(NSString *)apnDeviceToken
                            withCompletion:(void(^)(ALRegistrationResponse *message, NSError *error)) completion;

/// Updates notification modes the logged-in user can enable, disable sound, disable the notifications.
///
/// @param notificationMode An notification mode to update to applozic server.
///
/// The list of notification modes are:
/// - AL_NOTIFICATION_ENABLE_SOUND = 0, // Enables the notification sound.
/// - AL_NOTIFICATION_DISABLE_SOUND = 1, // Disable the sound of APNs notifiaction.
/// - AL_NOTIFICATION_ENABLE = 0, // Enables the notification.
/// - AL_NOTIFICATION_DISABLE = 2 // Disables the notifications.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the update notification failure.
+ (void)updateNotificationMode:(short)notificationMode
                withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion;
/// :nodoc:
- (void)connect DEPRECATED_ATTRIBUTE;

/// :nodoc:
- (void)disconnect DEPRECATED_ATTRIBUTE;

/// Logouts the user from Applozic server.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the logout failure.
/// @note Logout user will clear locally stored data of applozic logged-in user.
/// @warning Mostly  logout method `-[ALRegisterUserClientService logoutWithCompletionHandler:]` needs to be called on your App logout success.
- (void)logoutWithCompletionHandler:(void(^)(ALAPIResponse *response, NSError *error))completion;

/// Used for updating current Applozic App version code to apploizc server.
+ (BOOL)isAppUpdated;

/// Syncs the account status an internal method.
/// @deprecated Method wil be removed in future.
- (void)syncAccountStatus DEPRECATED_ATTRIBUTE;

/// Syncs the account pricing status of Application.
/// @param completion An `ALRegistrationResponse` describing a successful account status synced or An error describing the sync account failure.
- (void)syncAccountStatusWithCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion;

/// Used for updating logged-in user details to Applozic server.
///
/// @warning Instead use  `-[Applozic updateUserDisplayName:andUserImage:userStatus:withCompletion:];` method to update.
/// @param updatedUser An `ALUser` object.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the update user failure.
- (void)updateUser:(ALUser *)updatedUser withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion;

/// Update's APNs and VOIP token to applozic server.
///
/// @param apnsOrVoipDeviceToken Pass APNs or VOIP token.
/// @param isAPNsToken Pass YES in case of APNs token, NO in case of VOIP token.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise an error describing the update APNs or VOIP device token failure.
/// @note The method  `-[ALRegisterUserClientService updateAPNsOrVOIPDeviceToken:withApnTokenFlag:withCompletion:]` needs to used only in `ApplozicAudioVideo` SDK for updating VOIP or APN;s device token to Applozic Sever.
- (void)updateAPNsOrVOIPDeviceToken:(NSString *)apnsOrVoipDeviceToken
                   withApnTokenFlag:(BOOL)isAPNsToken
                     withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion;

/// Accessing currently stored (APN's) or (VOIP) device token.
- (NSString *)getRegistrationId;

@end
