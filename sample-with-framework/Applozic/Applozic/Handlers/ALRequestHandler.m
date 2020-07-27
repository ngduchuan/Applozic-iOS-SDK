//
//  ALRequestHandler.m
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALRequestHandler.h"
#import "ALUtilityClass.h"
#import "ALUserDefaultsHandler.h"
#import "NSString+Encode.h"
#import "ALUser.h"
#import "NSData+AES.h"
#import "ALAuthService.h"

static NSString *const REGISTER_USER_STRING = @"rest/ws/register/client";

@implementation ALRequestHandler

+(void ) createGETRequestWithUrlString:(NSString *) urlString
                           paramString:(NSString *) paramString
                        withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion {
    [self createGETRequestWithUrlString:urlString
                            paramString:paramString
                               ofUserId:nil
                         withCompletion:^(NSMutableURLRequest *theRequest, NSError *error) {
        completion(theRequest, error);
    }];
}

+(void) createGETRequestWithUrlString:(NSString *) urlString
                          paramString:(NSString *) paramString
                             ofUserId:(NSString *) userId
                       withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion {
    
    ALAuthService * authService = [[ALAuthService alloc] init];
    [authService validateAuthTokenAndRefreshWithCompletion:^(NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSMutableURLRequest * theRequest = [[NSMutableURLRequest alloc] init];
        NSURL * theUrl = nil;
        if (paramString != nil) {
            theUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",urlString,paramString]];
        } else {
            theUrl = [NSURL URLWithString:urlString];
        }
        ALSLog(ALLoggerSeverityInfo, @"GET_URL :: %@", theUrl);
        [theRequest setURL:theUrl];
        [theRequest setTimeoutInterval:600];
        [theRequest setHTTPMethod:@"GET"];
        [self addGlobalHeader:theRequest ofUserId:userId withAuthToken:[ALUserDefaultsHandler getAuthToken]];
        completion(theRequest, nil);
    }];
}

+(void) createPOSTRequestWithUrlString:(NSString *) urlString
                           paramString:(NSString *) paramString
                        withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion {
    [self createPOSTRequestWithUrlString:urlString
                             paramString:paramString
                                ofUserId:nil
                          withCompletion:^(NSMutableURLRequest *theRequest, NSError *error) {
        completion(theRequest, error);
    }];
}

+(void) createPOSTRequestWithUrlString:(NSString *) urlString
                           paramString:(NSString *) paramString
                              ofUserId:(NSString *)userId
                        withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion {
    
    
    ALAuthService * authService = [[ALAuthService alloc] init];
    [authService validateAuthTokenAndRefreshWithCompletion:^(NSError *error) {
        
        if (error) {
            completion(nil, error);
            return;
        }
        NSMutableURLRequest * theRequest = [self createPOSTRequestWithUrl:urlString
                                                              paramString:paramString withAuthToken:[ALUserDefaultsHandler getAuthToken] ofUserId:userId];
        completion(theRequest, nil);
    }];
}

+(NSMutableURLRequest *) createPOSTRequestWithUrl:(NSString *)urlString
                                      paramString:(NSString *) paramString
                                    withAuthToken: (NSString *) authToken
                                         ofUserId:(NSString *)userId {
    
    NSMutableURLRequest * theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [theRequest setTimeoutInterval:600];
    [theRequest setHTTPMethod:@"POST"];
    
    if (paramString != nil) {
        NSData * thePostData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
        if([ALUserDefaultsHandler getEncryptionKey] && ![urlString hasSuffix:REGISTER_USER_STRING] && ![urlString hasSuffix:@"rest/ws/register/update"]) {
            NSData *postData = [thePostData AES128EncryptedDataWithKey:[ALUserDefaultsHandler getEncryptionKey]];
            NSData *base64Encoded = [postData base64EncodedDataWithOptions:0];
            thePostData = base64Encoded;
        }
        [theRequest setHTTPBody:thePostData];
        [theRequest setValue:[NSString stringWithFormat:@"%lu",(unsigned long)[thePostData length]] forHTTPHeaderField:@"Content-Length"];
    }
    ALSLog(ALLoggerSeverityInfo, @"POST_URL :: %@", urlString);
    [self addGlobalHeader:theRequest ofUserId:userId withAuthToken:authToken];
    return theRequest;
}

+(NSMutableURLRequest *) createGETRequestWithUrlStringWithoutHeader:(NSString *) urlString
                                                        paramString:(NSString *) paramString {
    NSMutableURLRequest * theRequest = [[NSMutableURLRequest alloc] init];
    NSURL * theUrl = nil;
    if (paramString != nil) {
        theUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",urlString,paramString]];
    } else {
        theUrl = [NSURL URLWithString:urlString];
    }
    ALSLog(ALLoggerSeverityInfo, @"GET_URL :: %@", theUrl);
    [theRequest setURL:theUrl];
    [theRequest setTimeoutInterval:600];
    [theRequest setHTTPMethod:@"GET"];
    return theRequest;
}

+(void) createPatchRequestWithUrlString:(NSString *) urlString
                            paramString:(NSString *) paramString withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion {

    ALAuthService * authService = [[ALAuthService alloc] init];
    [authService validateAuthTokenAndRefreshWithCompletion:^(NSError *error) {

        if (error) {
            completion(nil, error);
            return;
        }
        NSMutableURLRequest * theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];

        NSURL *theUrl = nil;
        if (paramString != nil) {
            theUrl =
            [NSURL URLWithString: [NSString stringWithFormat:@"%@?%@", urlString, paramString]];
        } else {
            theUrl = [NSURL URLWithString: urlString];
        }
        [theRequest setURL:theUrl];
        [theRequest setTimeoutInterval:600];
        [theRequest setHTTPMethod:@"PATCH"];
        [self addGlobalHeader:theRequest ofUserId:nil withAuthToken:[ALUserDefaultsHandler getAuthToken]];
        ALSLog(ALLoggerSeverityInfo, @"PATCH_URL :: %@", theUrl);
        completion(theRequest, nil);
    }];
}

+(void) addGlobalHeader:(NSMutableURLRequest*) request
               ofUserId:(NSString *)userId
          withAuthToken:(NSString *)authToken {
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString * appMoudle = [ALUserDefaultsHandler getAppModuleName];
    if (appMoudle) {
        [request addValue:appMoudle forHTTPHeaderField:@"App-Module-Name"];
    }
    
    NSString * deviceKeyString = [ALUserDefaultsHandler getDeviceKeyString];
    if (deviceKeyString) {
        [request addValue:deviceKeyString forHTTPHeaderField:@"Device-Key"];
    }
    
    if (userId) {
        [request setValue:[userId urlEncodeUsingNSUTF8StringEncoding] forHTTPHeaderField:@"Of-User-Id"];
    }
    
    if (authToken) {
        [request addValue:authToken forHTTPHeaderField:@"X-Authorization"];
    }
    
    if ([ALUserDefaultsHandler getUserRoleType] == 8 && userId != nil) {
        NSString *product = @"true";
        [request setValue:product forHTTPHeaderField:@"Apz-Product-App"];
        [request addValue:[ALUserDefaultsHandler getApplicationKey] forHTTPHeaderField:@"Apz-AppId"];
    } else {
        [request addValue:[ALUserDefaultsHandler getApplicationKey] forHTTPHeaderField:@"Application-Key"];
    }
}


@end

