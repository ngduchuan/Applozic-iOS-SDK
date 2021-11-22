//
//  ALVerification.m
//  ApplozicCore
//
//  Created by Sunil on 19/11/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import "ALVerification.h"
#import "ALLogger.h"

@implementation ALVerification

+(void)verify:(BOOL)predicate withErrorMessage:(NSString *)message {

    if (predicate) {
        return;
    }
    ALSLog(ALLoggerSeverityWarn,@"%@", message);
}

+(void)verificationFailure:(NSError *)error {
    [self verificationFailure:error];
}

+(void)verificationFailure:(NSString *)errorMessage withError:(NSError *)error {
    ALSLog(ALLoggerSeverityError,@"Error :%@%@", errorMessage,  error.localizedDescription);
}

+(void)verificationFailureWithException:(NSException *)exception {
    ALSLog(ALLoggerSeverityError,@"Exception : %@", exception.description);
}

@end
