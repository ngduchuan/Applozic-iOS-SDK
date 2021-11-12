//
//  ALAuthClientService.h
//  Applozic
//
//  Created by Sunil on 15/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALAuthClientService` class is has methods for JWT token.
/// @warning `ALAuthClientService` class used only for internal purposes.
@interface ALAuthClientService : NSObject

/// Used for refreshing JWT auth token from server.
/// @param completion An `ALAPIResponse` will have status `AL_RESPONSE_SUCCESS` for successful otherwise, an error describing the refresh authtoken failure.
/// @note It will generate new JWT token when this is called.
- (void)refreshAuthTokenForLoginUserWithCompletion:(void (^)(ALAPIResponse * _Nullable apiResponse, NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
