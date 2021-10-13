//
//  ALAuthService.h
//  Applozic
//
//  Created by Sunil on 11/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

#import "ALAuthClientService.h"
#import "ALUserDefaultsHandler.h"
#import <Foundation/Foundation.h>

/// `ALAuthService` class is used for JWT token decode, validate auth token and refresh JWT token.
/// @warning `ALAuthService` class used only for internal purposes.
@interface ALAuthService : NSObject

/// Instance mthod of `ALAuthClientService`.
@property (nonatomic, strong) ALAuthClientService *authClientService;

/// Used for decode JWT token and save in user defaults.
/// @param authToken Pass the JWT auth token.
- (NSError *)decodeAndSaveToken:(NSString *)authToken;

/// Used for validating a JWT Auth token and refresh the JWT token.
/// @param completion In case of successful the error will be nil otherwise error will be present if their is any error.
- (void)validateAuthTokenAndRefreshWithCompletion:(void (^)(NSError * error))completion;

/// Used for refresh auth token the refreshed auth token is saved.
/// @param completion If ALAPIResponse response in callback if success or error and NSError if any error occurs.
- (void)refreshAuthTokenForLoginUserWithCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

@end
