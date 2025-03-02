//
//  ALInternalSettings.m
//  Applozic
//
//  Created by apple on 13/05/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALInternalSettings.h"
#import "ALUtilityClass.h"

static NSString *const AL_REGISTRATION_STATUS_MESSAGE = @"com.applozic.userdefault.REGISTRATION_STATUS_MESSAGE";
static NSString *const AL_REGISTERED = @"AL_REGISTERED";

@implementation ALInternalSettings

+ (void)setRegistrationStatusMessage:(NSString *)message {
    NSUserDefaults *userDefaults = [ALInternalSettings getUserDefaults];
    [userDefaults setValue:message forKey:AL_REGISTRATION_STATUS_MESSAGE];
    [userDefaults synchronize];
}

+ (NSString *)getRegistrationStatusMessage {
    NSUserDefaults *userDefaults = [ALInternalSettings getUserDefaults];
    NSString *pushRegistrationStatusMessage  =  [userDefaults valueForKey:AL_REGISTRATION_STATUS_MESSAGE];
    return pushRegistrationStatusMessage  != nil ? pushRegistrationStatusMessage : AL_REGISTERED;
}

+ (NSUserDefaults *)getUserDefaults {
    NSString *appSuiteName = [ALUtilityClass getAppGroupsName];
    return [[NSUserDefaults alloc] initWithSuiteName:appSuiteName];
}

@end
