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
    [self verificationFailure:nil withError:error];
}

+(void)verificationFailure:(NSString *)errorMessage withError:(NSError *)error {
    if (errorMessage) {
        ALSLog(ALLoggerSeverityError,@"%@%@", errorMessage, error.localizedDescription);
    } else {
        ALSLog(ALLoggerSeverityError,@"%@", error.localizedDescription);
    }
}

+(void)verificationFailureWithException:(NSException *)exception {
    ALSLog(ALLoggerSeverityError,@"Exception : %@", exception.description);
}

@end
