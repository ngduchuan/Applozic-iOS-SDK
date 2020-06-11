//
//  ALAuthService.m
//  Applozic
//
//  Created by Sunil on 11/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

#import "ALAuthService.h"

@implementation ALAuthService

-(void)parseAuthToken:(NSString *)authToken {

    if (authToken){
        [ALUserDefaultsHandler setAuthToken:authToken];
        NSError * jwtError;
        ALJWT * jwt = [ALJWT decodeWithJwt:authToken error:&jwtError];

        if (!jwtError && jwt.body) {
            NSDictionary * jwtBody = jwt.body;
            NSNumber *createdAtTime = [jwtBody objectForKey:@"createdAtTime"];
            NSNumber *validUptoInMins = [jwtBody objectForKey:@"validUpto"];

            if (createdAtTime) {
                [ALUserDefaultsHandler setAuthTokenCreatedAtTime:createdAtTime];
            }

            if (validUptoInMins) {
                [ALUserDefaultsHandler setAuthTokenValidUptoInMins:validUptoInMins];
            }
        }
    }
}

-(BOOL)isAuthTokenValid {

    NSNumber * authTokenCreatedAtTime = [ALUserDefaultsHandler getAuthTokenCreatedAtTime];
    NSNumber * authTokenValidUptoMins = [ALUserDefaultsHandler getAuthTokenValidUptoMins];

    NSTimeInterval timeInSeconds = [[NSDate date] timeIntervalSince1970] * 1000;

    return authTokenCreatedAtTime > 0 && authTokenValidUptoMins > 0 && (timeInSeconds - authTokenCreatedAtTime.doubleValue) / 60000 < authTokenValidUptoMins.doubleValue;

}

-(void) validateAuthTokenAndRefreshWithCompletion:(void (^)(NSError * error))completion {
    if (![self isAuthTokenValid]){
        ALRegisterUserClientService * registerUserClientService = [[ALRegisterUserClientService alloc]init];
        [registerUserClientService refreshAuthTokenForLoginUserWithCompletion:^(ALAPIResponse *apiResponse, NSError *error) {
            if (error) {
                completion(error);
                return;
            }
            completion(nil);
            return;
        }];
    }
    completion(nil);
}

@end
