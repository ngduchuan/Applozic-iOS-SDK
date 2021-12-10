//
//  ALAPIResponse.h
//  Applozic
//
//  Created by devashish on 19/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALErrorResponse.h"
#import "ALJson.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Success response constant text.
extern NSString *const AL_RESPONSE_SUCCESS;
/// Error response constant text.
extern NSString *const AL_RESPONSE_ERROR;

/// `ALAPIResponse` class is used for parsing the API response of Applozic.
@interface ALAPIResponse : ALJson

/// Status of the API call it will have `AL_RESPONSE_SUCCESS` or `AL_RESPONSE_ERROR`.
@property (nonatomic, strong) NSString * _Nullable status;

/// When the API call generated this wil have time in milliseconds.
@property (nonatomic, strong) NSNumber * _Nullable generatedAt;

/// This will have API response JSON.
@property (nonatomic, strong) id _Nullable response;

/// Actual JSON response string.
@property (nonatomic, strong) NSString * _Nullable actualresponse;

/// An error response in case of any error.
@property (nonatomic, strong) ALErrorResponse * _Nullable errorResponse;

- (instancetype)initWithJSONString:(NSString *)JSONString;

@end

NS_ASSUME_NONNULL_END
