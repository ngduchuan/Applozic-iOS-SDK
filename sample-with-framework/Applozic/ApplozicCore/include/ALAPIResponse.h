//
//  ALAPIResponse.h
//  Applozic
//
//  Created by devashish on 19/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"
/// Success response constant text .
extern NSString *const AL_RESPONSE_SUCCESS;
/// Error response constant text .
extern NSString *const AL_RESPONSE_ERROR;

/// `ALAPIResponse` class is used for parsing the API response of Applozic.
@interface ALAPIResponse : ALJson

/// Status of the API call it will have `AL_RESPONSE_SUCCESS` or `AL_RESPONSE_ERROR`.
@property (nonatomic, strong) NSString *status;

/// When the API call generated this wil have time in milliseconds.
@property (nonatomic, strong) NSNumber *generatedAt;

/// This will have API response JSON.
@property (nonatomic, strong) id response;

/// Actual JSON response string.
@property (nonatomic, strong) NSString *actualresponse;

@end
