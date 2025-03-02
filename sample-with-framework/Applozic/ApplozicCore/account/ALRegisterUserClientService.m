//
//  ALRegisterUserClientService.m
//  ChatApp
//
//  Created by devashish on 18/09/2015.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALApplozicSettings.h"
#import "ALAuthService.h"
#import "ALConstant.h"
#import "ALContactDBService.h"
#import "ALInternalSettings.h"
#import "ALLogger.h"
#import "ALMessageDBService.h"
#import "ALMessageService.h"
#import "ALMQTTConversationService.h"
#import "ALRegisterUserClientService.h"
#import "ALRegistrationResponse.h"
#import "ALUserDefaultsHandler.h"
#import "ALUserService.h"
#import "ALUtilityClass.h"
#import "ALVerification.h"

NSString *const AL_INVALID_APPLICATIONID = @"INVALID_APPLICATIONID";
NSString *const AL_LOGOUT_URL = @"/rest/ws/device/logout";
/// For internal use only.
static short AL_VERSION_CODE = 112;

@implementation ALRegisterUserClientService

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupServices];
    }
    return self;
}

- (void)setupServices {
    self.responseHandler = [[ALResponseHandler alloc] init];
}

- (void)initWithCompletion:(ALUser *)user
            withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion {
    
    if ([ALUserDefaultsHandler isLoggedIn]) {
        ALSLog(ALLoggerSeverityInfo, @"User is already login to applozic with userId %@",ALUserDefaultsHandler.getUserId);
        ALRegistrationResponse *registrationResponse = [self getLoginRegistrationResponse];
        completion(registrationResponse, nil);
        return;
    }
    
    NSString *loginURLString = [NSString stringWithFormat:@"%@/rest/ws/register/client",KBASE_URL];
    
    [ALUserDefaultsHandler setUserId:user.userId];
    [ALUserDefaultsHandler setPassword:user.password];
    [ALUserDefaultsHandler setDisplayName:user.displayName];
    [ALUserDefaultsHandler setEmailId:user.email];
    
    NSString *applicationId = [ALUserDefaultsHandler getApplicationKey];
    if (applicationId) {
        [user setApplicationId: applicationId];
    } else { // For backward compatibility
        [ALUserDefaultsHandler setApplicationKey: user.applicationId];
    }

    if (user.applicationId.length == 0) {
        NSError *error = [NSError errorWithDomain:@"Applozic"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey : @"Failed to login the user App-Id is nil."}];

        completion(nil, error);
        return;
    }

    [user setEmailVerified:true];
    [user setDeviceType:4];
    [user setAppVersionCode:AL_VERSION_CODE];
    
    NSString *registrationId = [self getRegistrationId];
    if (registrationId) {
        [user setRegistrationId:registrationId];
    }
    
    [user setNotificationMode:[ALUserDefaultsHandler getNotificationMode]];
    [user setAuthenticationTypeId:[ALUserDefaultsHandler getUserAuthenticationTypeId]];
    [user setPassword:[ALUserDefaultsHandler getPassword]];
    [user setUnreadCountType:[ALUserDefaultsHandler getUnreadCountType]];
    [user setDeviceApnsType:!isDevelopmentBuild()];
    [user setEnableEncryption:[ALUserDefaultsHandler getEnableEncryption]];
    [user setRoleName:[ALApplozicSettings getUserRoleName]];

    NSString *appModuleName = [ALUserDefaultsHandler getAppModuleName];

    if (appModuleName) {
        [user setAppModuleName:appModuleName];
    } else if (user.appModuleName != NULL) {
        [ALUserDefaultsHandler setAppModuleName:user.appModuleName];
    }

    if ([ALApplozicSettings isAudioVideoEnabled]) {
        [user setFeatures:[NSMutableArray arrayWithArray:[NSArray arrayWithObjects: @"101",@"102",nil]]];
    }

    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:user.dictionary options:0 error:&error];
    NSString *loginParamString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    NSString *logParamText = [self getUserParamTextForLogging:user];
    ALSLog(ALLoggerSeverityInfo, @"PARAM_STRING USER_REGISTRATION :: %@",logParamText);
    
    NSMutableURLRequest *loginUserRequest = [ALRequestHandler createPOSTRequestWithUrlString:loginURLString paramString:loginParamString];
    
    [self.responseHandler processRequest:loginUserRequest andTag:@"CREATE ACCOUNT" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        }

        NSString *loginAPIResponseJSON = (NSString *)jsonResponse;

        [ALVerification verify:loginAPIResponseJSON != nil withErrorMessage:@"Registration response object for login is nil."];

        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_USER_REGISTRATION :: %@", loginAPIResponseJSON);

        if (!loginAPIResponseJSON) {
            NSError *nilResponseError = [NSError errorWithDomain:@"Applozic"
                                                            code:1
                                                        userInfo:@{NSLocalizedDescriptionKey : @"Failed to login registration response object is nil."}];

            completion(nil, nilResponseError);
            return;
        }

        ALRegistrationResponse *response = [[ALRegistrationResponse alloc] initWithJSONString:loginAPIResponseJSON];
        
        // Only save the UserDefaults for successful register.
        if ([response isRegisteredSuccessfully]) {
            
            @try
            {
                [ALUserDefaultsHandler setUserId:user.userId];
                [ALUserDefaultsHandler setEmailVerified:user.emailVerified];
                [ALUserDefaultsHandler setDisplayName:user.displayName];
                [ALUserDefaultsHandler setEmailId:user.email];
                [ALUserDefaultsHandler setDeviceKeyString:response.deviceKey];
                [ALUserDefaultsHandler setUserKeyString:response.userKey];
                [ALUserDefaultsHandler setUserPricingPackage:response.pricingPackage];
                [ALUserDefaultsHandler setLastSyncTimeForMetaData:[NSNumber numberWithDouble:[response.currentTimeStamp doubleValue]]];
                [ALUserDefaultsHandler setLastSyncTime:[NSNumber numberWithDouble:[response.currentTimeStamp doubleValue]]];
                [ALUserDefaultsHandler setLastSyncChannelTime:(NSNumber *)response.currentTimeStamp];
                
                if (user.pushNotificationFormat) {
                    [ALUserDefaultsHandler setPushNotificationFormat:user.pushNotificationFormat];
                }
                
                if (response.roleType) {
                    [ALUserDefaultsHandler setUserRoleType:response.roleType];
                }
                
                if (response.notificationSoundFileName ) {
                    [ALUserDefaultsHandler setNotificationSoundFileName:response.notificationSoundFileName];
                }
                
                if (response.userEncryptionKey) {
                    [ALUserDefaultsHandler setUserEncryption:response.userEncryptionKey];
                }
                
                if (response.statusMessage) {
                    [ALUserDefaultsHandler setLoggedInUserStatus:response.statusMessage];
                }
                if (response.brokerURL && ![response.brokerURL isEqualToString:@""]) {
                    NSArray * mqttURL = [response.brokerURL componentsSeparatedByString:@":"];
                    NSString * MQTTURL = [mqttURL[1] substringFromIndex:2];
                    ALSLog(ALLoggerSeverityInfo, @"MQTT_URL :: %@",MQTTURL);
                    [ALUserDefaultsHandler setMQTTURL:MQTTURL];
                }
                if (response.encryptionKey) {
                    [ALUserDefaultsHandler setEncryptionKey:response.encryptionKey];
                }
                
                if (response.message) {
                    [ALInternalSettings setRegistrationStatusMessage:response.message];
                }
                
                ALAuthService *authService = [[ALAuthService alloc] init];
                [authService decodeAndSaveToken:response.authToken];
                
                ALContactDBService  *contactDBService = [[ALContactDBService alloc] init];
                ALContact *contact = [[ALContact alloc] init];
                contact.userId = user.userId;
                contact.displayName = response.displayName;
                contact.contactImageUrl = response.imageLink;
                contact.contactNumber = response.contactNumber;
                contact.roleType = [NSNumber numberWithShort:response.roleType];
                contact.metadata = response.metadata;
                contact.userStatus = response.statusMessage;
                [contactDBService addContactInDatabase:contact];
                
            } @catch (NSException *exception) {

                NSString *errorMessage = [[NSString alloc] initWithFormat:@"Exception in login: %@", exception.reason];

                NSError *exceptionError = [NSError errorWithDomain:@"Applozic"
                                                              code:1
                                                          userInfo:@{NSLocalizedDescriptionKey : errorMessage}];

                [ALVerification verificationFailure:exceptionError];
                completion(nil, exceptionError);
                return;
            }

            completion(response, nil);
            
            ALUserService *userService = [ALUserService new];
            [userService getMutedUserListWithDelegate:nil withCompletion:^(NSMutableArray *userDetailArray, NSError *error) {
                
            }];
        } else {
            completion(response, nil);
        }
    }];
    
}

- (void)updateApnDeviceTokenWithCompletion:(NSString *)apnDeviceToken
                            withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion {
    ALSLog(ALLoggerSeverityInfo, @"ApnDeviceToken ## %@", apnDeviceToken);
    
    if (apnDeviceToken.length == 0) {
        NSError *error = [NSError errorWithDomain:@"Applozic"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey : @"ApnDeviceToken can not be empty or nil"}];
        
        completion(nil, error);
        return;
    }
    
    [ALUserDefaultsHandler setApnDeviceToken:apnDeviceToken];
    if ([ALUserDefaultsHandler isLoggedIn]) {
        
        [self updateDeviceToken:apnDeviceToken withCompletion:^(ALRegistrationResponse *response, NSError *error) {
            completion(response,error);
        }];
    }
}

- (void)updateAPNsOrVOIPDeviceToken:(NSString *)apnsOrVoipDeviceToken
                   withApnTokenFlag:(BOOL)isAPNsToken
                     withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion {
    
    if (apnsOrVoipDeviceToken.length == 0) {
        NSError *error = [NSError errorWithDomain:@"Applozic"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey : @"ApnOrVoipDeviceToken can not be empty or nil"}];
        
        completion(nil, error);
        return;
    }
    
    ALUser *user = [[ALUser alloc] init];
    [user setNotificationMode:ALUserDefaultsHandler.getNotificationMode];
    
    if (isAPNsToken) {
        [ALUserDefaultsHandler setApnDeviceToken:apnsOrVoipDeviceToken];
    } else {
        [ALUserDefaultsHandler setVOIPDeviceToken:apnsOrVoipDeviceToken];
    }
    
    if (![ALUserDefaultsHandler isLoggedIn]) {
        ALSLog(ALLoggerSeverityInfo, @"Ignoring APNs and VOIP token server call update as user is not logged in applozic and stored the token in user defaults for future use");
        return;
    }
    
    NSString *apnsVOIPDeviceToken = [self getAPNsAndVOIPDeviceToken];
    if (apnsVOIPDeviceToken) {
        ALSLog(ALLoggerSeverityInfo, @"APNs and VOIP token both are exist calling server for updating token");
        [user setRegistrationId:apnsVOIPDeviceToken];
        [self updateUser:user withCompletion:^(ALRegistrationResponse *response, NSError *error) {
            if (error) {
                completion(nil, error);
                return;
            }
            if (![response isRegisteredSuccessfully]) {
                NSError *error = [NSError errorWithDomain:@"Applozic"
                                                     code:1
                                                 userInfo:@{NSLocalizedDescriptionKey : response.message}];
                completion(nil, error);
                return;
            }
            completion(response, error);
        }];
    } else {
        ALSLog(ALLoggerSeverityInfo, @"Ignoring APNs and VOIP token server call update either token doesn't exist");
    }
}

/// This method will return the apns and VOIP token in case if both token are there in user defauls
- (NSString *)getAPNsAndVOIPDeviceToken {
    NSString *apnAndVOIPToken = nil;
    
    NSString *apnsDeviceToken = [ALUserDefaultsHandler getApnDeviceToken];
    NSString *VOIPDeviceToken = [ALUserDefaultsHandler getVOIPDeviceToken];
    if (apnsDeviceToken.length != 0 &&
        VOIPDeviceToken.length != 0) {
        // The format of the string is APNS token,VOIP token
        apnAndVOIPToken = [[NSString alloc] initWithFormat:@"%@,%@", apnsDeviceToken, VOIPDeviceToken];
    }
    return apnAndVOIPToken;
}

- (NSString *)getRegistrationId {
    NSString *registrationId = nil;
    if ([ALApplozicSettings isAudioVideoEnabled]) {
        registrationId = [self getAPNsAndVOIPDeviceToken];
    } else {
        registrationId = [ALUserDefaultsHandler getApnDeviceToken];
    }
    return registrationId;
}

- (void)updateDeviceToken:(NSString *)apnDeviceToken withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion {
    ALUser *user = [[ALUser alloc] init];
    [user setNotificationMode:ALUserDefaultsHandler.getNotificationMode];
    [user setRegistrationId:apnDeviceToken];
    
    [self updateUser:user withCompletion:^(ALRegistrationResponse *response, NSError *error) {
        completion(response, error);
    }];
}

+ (void)updateNotificationMode:(short)notificationMode withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion {
    
    ALUser *user = [[ALUser alloc] init];
    [user setNotificationMode:notificationMode];
    
    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService updateUser:user withCompletion:^(ALRegistrationResponse *response, NSError *error) {
        completion(response, error);
    }];
}

- (void)updateUser:(ALUser *)updatedUser withCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion {
    
    NSString *userUpdateURLString = [NSString stringWithFormat:@"%@/rest/ws/register/update",KBASE_URL];
    
    ALUser *user = [ALUser new];
    
    [user setUserId:[ALUserDefaultsHandler getUserId]];
    [user setApplicationId:[ALUserDefaultsHandler getApplicationKey]];
    [user setNotificationMode:updatedUser.notificationMode];
    [user setPassword:[ALUserDefaultsHandler getPassword]];
    
    if (updatedUser.registrationId) {
        [user setRegistrationId:updatedUser.registrationId];
    } else {
        NSString *registrationId = [self getRegistrationId];
        if (registrationId) {
            [user setRegistrationId:registrationId];
        }
    }
    [user setEnableEncryption:[ALUserDefaultsHandler getEnableEncryption]];
    [user setEmailVerified:true];
    [user setDeviceType:4];
    [user setDeviceApnsType:!isDevelopmentBuild()];
    [user setAppVersionCode:AL_VERSION_CODE];
    [user setAuthenticationTypeId:[ALUserDefaultsHandler getUserAuthenticationTypeId]];
    [user setRoleName:[ALApplozicSettings getUserRoleName]];
    
    if (updatedUser.displayName) {
        user.displayName = updatedUser.displayName;
    }
    
    if (updatedUser.contactNumber) {
        user.contactNumber = updatedUser.contactNumber;
    }
    
    if (updatedUser.email) {
        user.email = updatedUser.email;
    }
    
    if ([ALUserDefaultsHandler getAppModuleName] != NULL) {
        [user setAppModuleName:[ALUserDefaultsHandler getAppModuleName]];
    }
    [user setPushNotificationFormat:[ALUserDefaultsHandler getPushNotificationFormat]];
    
    if (updatedUser.notificationSoundFileName) {
        [user setNotificationSoundFileName:updatedUser.notificationSoundFileName];
    } else if ([ALUserDefaultsHandler getNotificationSoundFileName] != nil) {
        [user setNotificationSoundFileName:[ALUserDefaultsHandler getNotificationSoundFileName]];
    }
    
    if ([ALApplozicSettings isAudioVideoEnabled]) {
        [user setFeatures:[NSMutableArray arrayWithArray:[NSArray arrayWithObjects: @"101",@"102",nil]]];
    }

    [user setUnreadCountType:[ALUserDefaultsHandler getUnreadCountType]];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:user.dictionary options:0 error:&error];
    NSString *userUpdateParamString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *userUpdateRequest = [ALRequestHandler createPOSTRequestWithUrlString:userUpdateURLString paramString:userUpdateParamString];
    
    [self.responseHandler authenticateAndProcessRequest:userUpdateRequest andTag:@"UPDATE USER DETAILS" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        ALSLog(ALLoggerSeverityInfo, @"Update login user details %@", jsonResponse);
        
        NSString *updateUserAPIResponse = (NSString *)jsonResponse;
        if (error) {
            completion(nil, error);
            return;
        }

        [ALVerification verify:updateUserAPIResponse != nil withErrorMessage:@"Register update user response object is nil."];

        if (!updateUserAPIResponse) {
            NSError *nilResponseError = [NSError errorWithDomain:@"Applozic"
                                                            code:1
                                                        userInfo:@{NSLocalizedDescriptionKey : @"Failed to register update user response object is nil."}];

            completion(nil, nilResponseError);
            return;
        }

        ALRegistrationResponse *response = [[ALRegistrationResponse alloc] initWithJSONString:updateUserAPIResponse];
        
        if (response && response.isRegisteredSuccessfully) {
            
            if (response.displayName) {
                [ALUserDefaultsHandler setDisplayName: response.displayName];
            }
            
            [ALUserDefaultsHandler setUserPricingPackage:response.pricingPackage];
            
            if (response.message) {
                [ALInternalSettings setRegistrationStatusMessage:response.message];
            }
            
            if (response.notificationSoundFileName) {
                [ALUserDefaultsHandler setNotificationSoundFileName:response.notificationSoundFileName];
            }
            
            if (response.authToken) {
                [ALUserDefaultsHandler setAuthToken:response.authToken];
            }
            
            [ALUserDefaultsHandler setUserRoleType:response.roleType];
            
        }
        completion(response, error);
        
    }];
}

- (void)syncAccountStatusWithCompletion:(void(^)(ALRegistrationResponse *response, NSError *error)) completion {
    ALUser *user = [[ALUser alloc] init];
    [user setNotificationMode:ALUserDefaultsHandler.getNotificationMode];
    NSString *registrationId = [self getRegistrationId];
    if (registrationId) {
        [user setRegistrationId:registrationId];
    }
    
    [self updateUser:user withCompletion:^(ALRegistrationResponse *response, NSError *error) {
        completion(response, error);
    }];
}


- (void) connect {
}

- (void) disconnect {
}

- (void)logoutWithCompletionHandler:(void(^)(ALAPIResponse *response, NSError *error))completion {
    NSString *logoutURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, AL_LOGOUT_URL];
    NSMutableURLRequest *logoutRequest = [ALRequestHandler createPOSTRequestWithUrlString:logoutURLString paramString:nil];
    
    [self.responseHandler authenticateAndProcessRequest:logoutRequest andTag:@"USER_LOGOUT"
                                  WithCompletionHandler:^(id jsonResponse, NSError *error) {

        if (error) {
            [ALVerification verify:jsonResponse != nil withErrorMessage:@"Logout response is nil."];
        }

        NSString *userKey = [ALUserDefaultsHandler getUserKeyString];
        BOOL completed = [[ALMQTTConversationService sharedInstance] unsubscribeToConversation:userKey];
        ALSLog(ALLoggerSeverityInfo, @"Unsubscribed to conversation after logout: %d", completed);

        [ALUserDefaultsHandler clearAll];
        [ALApplozicSettings clearAll];

        ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
        [messageDBService deleteAllObjectsInCoreData];
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in logout: %@", error.description);
            [[UIApplication sharedApplication] unregisterForRemoteNotifications];
            completion(nil, error);
        } else {
            ALSLog(ALLoggerSeverityInfo, @"RESPONSE_USER_LOGOUT :: %@", (NSString *)jsonResponse);
            ALAPIResponse *response = [[ALAPIResponse alloc] initWithJSONString:jsonResponse];
            completion(response, error);
        }
    }];
}

+ (BOOL)isAppUpdated {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentAppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *previousVersion = [userDefaults objectForKey:@"appVersion"];
    
    if (!previousVersion) {
        [userDefaults setObject:currentAppVersion forKey:@"appVersion"];
        [userDefaults synchronize];
        return NO;
    } else if ([previousVersion isEqualToString:currentAppVersion]) {
        return NO;
    } else {
        [ALRegisterUserClientService sendServerRequestForAppUpdate];
        [userDefaults setObject:currentAppVersion forKey:@"appVersion"];
        [userDefaults synchronize];
        return YES;
    }
    
}

+ (void)sendServerRequestForAppUpdate {
    
    NSString *appUpdateURLString = [NSString stringWithFormat:@"%@/rest/ws/register/version/update",KBASE_URL];
    NSString *paramString = [NSString stringWithFormat:@"appVersionCode=%i&deviceKey=%@", AL_VERSION_CODE, [ALUserDefaultsHandler getDeviceKeyString]];
    
    NSMutableURLRequest *appUpdateRequest = [ALRequestHandler createGETRequestWithUrlString:appUpdateURLString paramString:paramString];
    ALResponseHandler *responseHandler = [[ALResponseHandler alloc] init];
    [responseHandler authenticateAndProcessRequest:appUpdateRequest andTag:@"APP_UPDATED" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Update version error:%@",error);
            return;
        }
        ALSLog(ALLoggerSeverityInfo, @"Response: APP UPDATED:%@",jsonResponse);
    }];
}

- (void)syncAccountStatus {
    NSString *accountURLString = [NSString stringWithFormat:@"%@/rest/ws/application/pricing/package", KBASE_URL];
    NSString *accountParamString = [NSString stringWithFormat:@"applicationId=%@", [ALUserDefaultsHandler getApplicationKey]];
    
    NSMutableURLRequest *syncAccountRequest = [ALRequestHandler createGETRequestWithUrlString:accountURLString paramString:accountParamString];
    
    [self.responseHandler authenticateAndProcessRequest:syncAccountRequest andTag:@"SYNC_ACCOUNT_STATUS" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        
        ALSLog(ALLoggerSeverityInfo, @"Response of account Status :: %@",(NSString *)jsonResponse);
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Failed to sync the account status of App with error :: %@", error.description);
        }
    }];
}

- (ALRegistrationResponse *)getLoginRegistrationResponse {
    ALRegistrationResponse *registrationResponse = [[ALRegistrationResponse alloc] init];
    registrationResponse.deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    registrationResponse.userKey = [ALUserDefaultsHandler getUserKeyString];
    registrationResponse.message = [ALInternalSettings getRegistrationStatusMessage];
    ALContactDBService *contactDatabase = [[ALContactDBService alloc] init];
    ALContact *loginUserContact = [contactDatabase loadContactByKey:@"userId"value:[ALUserDefaultsHandler getUserId]];
    registrationResponse.contactNumber = loginUserContact.contactNumber;
    registrationResponse.lastSyncTime = [[ALUserDefaultsHandler getLastSyncTime] stringValue];
    registrationResponse.imageLink = loginUserContact.contactImageUrl;
    registrationResponse.encryptionKey = [ALUserDefaultsHandler getEncryptionKey];
    registrationResponse.pricingPackage = [ALUserDefaultsHandler getUserPricingPackage];
    registrationResponse.brokerURL = [NSString stringWithFormat:@"tcp://%@:%@",[ALUserDefaultsHandler getMQTTURL],[ALUserDefaultsHandler getMQTTPort]];
    registrationResponse.displayName = loginUserContact.displayName;
    registrationResponse.notificationSoundFileName = [ALUserDefaultsHandler getNotificationSoundFileName];
    registrationResponse.statusMessage = [ALUserDefaultsHandler getLoggedInUserStatus];
    registrationResponse.metadata = loginUserContact.metadata;
    registrationResponse.roleType = [ALUserDefaultsHandler getUserRoleType];
    registrationResponse.userEncryptionKey  = [ALUserDefaultsHandler getUserEncryptionKey];

    return registrationResponse;
}

- (NSString *)getUserParamTextForLogging:(ALUser *)user {
    NSString *passwordText = user.password ? @"***":@"";
    [user setPassword: passwordText];
    NSError *error;
    NSData *userData = [NSJSONSerialization dataWithJSONObject:user.dictionary options:0 error:&error];
    NSString *logParamString = [[NSString alloc] initWithData:userData encoding:NSUTF8StringEncoding];
    return logParamString;
}

static BOOL isDevelopmentBuild(void) {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    static BOOL isDevelopment = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // There is no provisioning profile in AppStore Apps.
        NSData *data = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"]];
        if (data) {
            const char *bytes = [data bytes];
            NSMutableString *profile = [[NSMutableString alloc] initWithCapacity:data.length];
            for (NSUInteger i = 0; i < data.length; i++) {
                [profile appendFormat:@"%c", bytes[i]];
            }
            // Look for debug value, if detected we're a development build.
            NSString *cleared = [[profile componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
            isDevelopment = [cleared rangeOfString:@"<key>get-task-allow</key><true/>"].length > 0;
        }
    });
    return isDevelopment;
#endif
}

@end

