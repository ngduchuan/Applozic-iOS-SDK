//
//  ALAuthService.h
//  Applozic
//
//  Created by Sunil on 11/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALUserDefaultsHandler.h"
#import "ALAuthClientService.h"

/// `ALAuthService` class is used for JWT token decode, validate auth token and refresh JWT token.
@interface ALAuthService : NSObject

/// Instance mthod of `ALAuthClientService`.
@property (nonatomic, strong) ALAuthClientService *authClientService;

/// This method is used for decode JWT token And save in user defaults.
/// @param authToken Pass the JWT auth token.
- (NSError *)decodeAndSaveToken:(NSString *)authToken;

/// This method used for validating a JWT Auth token and refresh the JWT token.
/// @param completion In case of successful the error will be nil otherwise error will be present if their is any error.
- (void)validateAuthTokenAndRefreshWithCompletion:(void (^)(NSError * error))completion;

/// This method is used for refresh auth token.
/// @param completion If ALAPIResponse response in callback if success or error and NSError if any error occurs.
- (void)refreshAuthTokenForLoginUserWithCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;

@end
