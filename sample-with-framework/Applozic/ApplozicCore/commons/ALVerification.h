//
//  ALVerification.h
//  ApplozicCore
//
//  Created by Sunil on 19/11/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALVerification : NSObject

+(void)verify:(BOOL)predicate withErrorMessage:(NSString *)message;

+(void)verificationFailure:(NSError *)error;

+(void)verificationFailureWithException:(NSException *)exception;


@end

NS_ASSUME_NONNULL_END
