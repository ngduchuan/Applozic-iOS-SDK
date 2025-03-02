//
//  ALAuthClientService.m
//  Applozic
//
//  Created by Sunil on 15/06/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

#import "ALAuthClientService.h"
#import "ALConstant.h"
#import "ALLogger.h"
#import "ALResponseHandler.h"
#import "ALUserDefaultsHandler.h"
#import "NSData+AES.h"
#import <Foundation/Foundation.h>
#import "ALVerification.h"

@implementation ALAuthClientService

static NSString *const USERID = @"userId";
static NSString *const APPLICATIONID = @"applicationId";
static NSString *const AL_AUTH_TOKEN_REFRESH_URL = @"/rest/ws/register/refresh/token";
static NSString *const message_SomethingWentWrong = @"SomethingWentWrong";

- (void)refreshAuthTokenForLoginUserWithCompletion:(void (^)(ALAPIResponse *apiResponse, NSError *error))completion {

    if (![ALUserDefaultsHandler isLoggedIn] || ![ALUserDefaultsHandler getApplicationKey]) {
        NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                userInfo:[NSDictionary dictionaryWithObject:@"User is not logged in or applicationId is nil"
                                                                                     forKey:NSLocalizedDescriptionKey]];
        completion(nil, reponseError);
        return;
    }

    NSMutableDictionary *JSONDictionary = [NSMutableDictionary new];
    [JSONDictionary setObject:[ALUserDefaultsHandler getUserId] forKey:USERID];
    [JSONDictionary setObject:[ALUserDefaultsHandler getApplicationKey] forKey:APPLICATIONID];

    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:&error];
    NSString *refreshTokenParamString = [[NSString alloc] initWithData:postdata encoding: NSUTF8StringEncoding];

    NSString *refreshTokenURLString = [NSString stringWithFormat:@"%@%@", KBASE_URL, AL_AUTH_TOKEN_REFRESH_URL];

    NSMutableURLRequest *refreshTokenRequest = [self createPostRequestWithURL:refreshTokenURLString withParamString:refreshTokenParamString];

    [self processRequest:refreshTokenRequest andTag:@"REFRESH_AUTH_TOKEN_OF_USER" WithCompletionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            ALSLog(ALLoggerSeverityError, @"Error in refreshing a auth token for user  : %@", error);
            completion(nil, error);
            return;
        }

        NSString *responseString = (NSString *)jsonResponse;
        ALSLog(ALLoggerSeverityInfo, @"RESPONSE_REFRESH_AUTH_TOKEN_OF_USER : %@",responseString);

        [ALVerification verify:responseString != nil withErrorMessage:@"Refresh auth token an API response is nil."];

        if (!responseString) {
            NSError *nilResponseError = [NSError errorWithDomain:@"Applozic"
                                                            code:1
                                                        userInfo:@{NSLocalizedDescriptionKey : @"Failed to refresh auth token an API response is nil."}];

            completion(nil, nilResponseError);
            return;
        }

        ALAPIResponse *apiResponse = [[ALAPIResponse alloc] initWithJSONString:responseString];

        if ([apiResponse.status isEqualToString:AL_RESPONSE_ERROR]) {
            NSString *errorMessage = [apiResponse.errorResponse errorDescriptionMessage];
            NSError *reponseError = [NSError errorWithDomain:@"Applozic" code:1
                                                    userInfo:[NSDictionary dictionaryWithObject: errorMessage == nil ? @"Failed to refresh auth token an API error occurred.": errorMessage
                                                                                         forKey:NSLocalizedDescriptionKey]];



            completion(nil, reponseError);
            return;
        }

        completion(apiResponse, nil);
    }];
}

-(NSMutableURLRequest *)createPostRequestWithURL:(NSString *)urlString
                                 withParamString:(NSString *)paramString {

    NSMutableURLRequest *postURLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [postURLRequest setTimeoutInterval:600];
    [postURLRequest setHTTPMethod:@"POST"];

    if (paramString != nil) {
        NSData *postRequestData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
        [postURLRequest setHTTPBody:postRequestData];
        [postURLRequest setValue:[NSString stringWithFormat:@"%lu",(unsigned long)[postRequestData length]] forHTTPHeaderField:@"Content-Length"];
    }
    [postURLRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *appMoudle = [ALUserDefaultsHandler getAppModuleName];
    if (appMoudle) {
        [postURLRequest addValue:appMoudle forHTTPHeaderField:@"App-Module-Name"];
    }
    NSString *deviceKeyString = [ALUserDefaultsHandler getDeviceKeyString];

    if (deviceKeyString) {
        [postURLRequest addValue:deviceKeyString forHTTPHeaderField:@"Device-Key"];
    }
    [postURLRequest addValue:[ALUserDefaultsHandler getApplicationKey] forHTTPHeaderField:@"Application-Key"];
    return postURLRequest;
}

- (void)processRequest:(NSMutableURLRequest *)request
                andTag:(NSString *)tag
 WithCompletionHandler:(void (^)(id, NSError *))reponseCompletion {

    NSURLSessionDataTask *sessionDataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *connectionError) {

        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;

        if (connectionError.code == kCFURLErrorUserCancelledAuthentication) {
            NSString *failingURL = connectionError.userInfo[@"NSErrorFailingURLStringKey"] != nil ? connectionError.userInfo[@"NSErrorFailingURLStringKey"]:@"Empty";
            ALSLog(ALLoggerSeverityError, @"Authentication error: HTTP 401 : ERROR CODE : %ld, FAILING URL: %@",  (long)connectionError.code,  failingURL);

            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil, [self errorWithDescription:@"Authentication error: 401"]);
            });
            return;
        } else if (connectionError.code == kCFURLErrorNotConnectedToInternet) {
            NSString *failingURL = connectionError.userInfo[@"NSErrorFailingURLStringKey"] != nil ? connectionError.userInfo[@"NSErrorFailingURLStringKey"]:@"Empty";
            ALSLog(ALLoggerSeverityError, @"NO INTERNET CONNECTIVITY, ERROR CODE : %ld, FAILING URL: %@",  (long)connectionError.code, failingURL);
            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil, [self errorWithDescription:@"No Internet connectivity"]);
            });
            return;
        } else if (connectionError) {
            ALSLog(ALLoggerSeverityError, @"ERROR_RESPONSE : %@ && ERROR:CODE : %ld ", connectionError.description, (long)connectionError.code);
            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil, [self errorWithDescription:connectionError.localizedDescription]);
            });
            return;
        }

        if (httpURLResponse.statusCode != 200 && httpURLResponse.statusCode != 201) {
            NSMutableString *errorString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            ALSLog(ALLoggerSeverityError, @"API request failed with status code: %ld response:%@",(long)httpURLResponse.statusCode, errorString);
            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil, [self errorWithDescription:message_SomethingWentWrong]);
            });
            return;
        }

        if (data == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil, [self errorWithDescription:@"API Response body is empty"]);
            });
            ALSLog(ALLoggerSeverityError, @"API Response body is empty for TAG :%@", tag);
            return;
        }

        id jsonResponse = nil;

        // DECRYPTING DATA WITH KEY
        if ([ALUserDefaultsHandler getEncryptionKey] &&
            ![tag isEqualToString:@"CREATE ACCOUNT"] &&
            ![tag isEqualToString:@"CREATE FILE URL"] &&
            ![tag isEqualToString:@"UPDATE NOTIFICATION MODE"] &&
            ![tag isEqualToString:@"FILE DOWNLOAD URL"]) {

            NSData *base64DecodedData = [[NSData alloc] initWithBase64EncodedData:data options:0];
            NSData *decryptedData = [base64DecodedData AES128DecryptedDataWithKey:[ALUserDefaultsHandler getEncryptionKey]];

            if (decryptedData == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    reponseCompletion(nil, [self errorWithDescription:message_SomethingWentWrong]);
                });
                ALSLog(ALLoggerSeverityError, @"API Response body failed to decrypt the data for TAG : %@", tag);
                return;
            }

            if (decryptedData.bytes) {

                NSString *dataToString = [NSString stringWithUTF8String:[decryptedData bytes]];

                data = [dataToString dataUsingEncoding:NSUTF8StringEncoding];

            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    reponseCompletion(nil, [self errorWithDescription:message_SomethingWentWrong]);
                });
                ALSLog(ALLoggerSeverityError, @"API Response body failed to decrypt the data is empty for TAG : %@", tag);
                return;
            }
        }

        if ([tag isEqualToString:@"CREATE FILE URL"] ||
            [tag isEqualToString:@"IMAGE POSTING"]) {
            jsonResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            /*TODO: Right now server is returning server's Error with tag <html>.
             it should be proper jason response with errocodes.
             We need to remove this check once fix will be done in server.*/

            NSError *error = [self checkForServerError:jsonResponse withRequestURL:request.URL.absoluteString];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    reponseCompletion(nil, error);
                });
                return;
            }
        } else {
            NSError *jsonError = nil;

            jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];

            if (jsonError) {
                NSMutableString *responseString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                //CHECK HTML TAG FOR ERROR
                NSError *error = [self checkForServerError:jsonResponse withRequestURL:request.URL.absoluteString];
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        reponseCompletion(nil, error);
                    });
                    return;
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        reponseCompletion(responseString, nil);
                    });
                    return;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            reponseCompletion(jsonResponse, nil);
        });
    }];
    [sessionDataTask resume];
}

- (NSError *)errorWithDescription:(NSString *)reason {
    return [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey]];
}

- (NSError *)checkForServerError:(NSString *)response withRequestURL:(NSString *)url {

    BOOL hasHTMLPrefixInResponse = [response hasPrefix:@"<html>"];

    [ALVerification
     verify:!hasHTMLPrefixInResponse
     withErrorMessage:[[NSString alloc] initWithFormat:@"Failed request the response has HTML prefix in it for request URL :%@", url]];

    if (hasHTMLPrefixInResponse || [response isEqualToString:[@"error" uppercaseString]]) {
        NSError *error = [NSError errorWithDomain:@"Internal Error" code:500 userInfo:nil];
        return error;
    }
    return nil;
}

@end
