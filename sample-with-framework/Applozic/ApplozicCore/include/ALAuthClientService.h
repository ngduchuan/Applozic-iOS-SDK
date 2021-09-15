//
//  ALAuthClientService.h
//  Applozic
//
//  Created by Sunil on 15/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAPIResponse.h"

/// `ALAuthClientService` class is has methods for JWT token.
@interface ALAuthClientService : NSObject

/// This method is used for refreshing JWT auth token from server.
/// @param completion <#completion description#>
/// @note This method will generate new JWT token when this is called.
- (void)refreshAuthTokenForLoginUserWithCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion;
@end
