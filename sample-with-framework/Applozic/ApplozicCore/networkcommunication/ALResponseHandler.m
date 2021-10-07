//
//  ALResponseHandler.m
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALResponseHandler.h"
#import "NSData+AES.h"
#import "ALUserDefaultsHandler.h"
#import "ALAuthService.h"
#import "ALLogger.h"

@implementation ALResponseHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupService];
    }
    return self;
}

-(void)setupService {
    self.authService = [[ALAuthService alloc] init];
}

static NSString *const message_SomethingWentWrong = @"SomethingWentWrong";

- (void)processRequest:(NSMutableURLRequest *)request
                andTag:(NSString *)tag
 WithCompletionHandler:(void (^)(id jsonResponse, NSError *error))reponseCompletion {

    NSURLSessionDataTask *sessionDataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *connectionError) {

        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;

        if (connectionError.code == kCFURLErrorUserCancelledAuthentication) {
            NSString *failingURL = connectionError.userInfo[@"NSErrorFailingURLStringKey"] != nil ? connectionError.userInfo[@"NSErrorFailingURLStringKey"]:@"Empty";
            ALSLog(ALLoggerSeverityError, @"Authentication error: HTTP 401 : ERROR CODE : %ld, FAILING URL: %@",  (long)connectionError.code,  failingURL);

            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil,[self errorWithDescription:@"Authentication error: 401"]);
            });
            return;
        } else if (connectionError.code == kCFURLErrorNotConnectedToInternet) {
            NSString *failingURL = connectionError.userInfo[@"NSErrorFailingURLStringKey"] != nil ? connectionError.userInfo[@"NSErrorFailingURLStringKey"]:@"Empty";
            ALSLog(ALLoggerSeverityError, @"NO INTERNET CONNECTIVITY, ERROR CODE : %ld, FAILING URL: %@",  (long)connectionError.code, failingURL);
            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil,[self errorWithDescription:@"No Internet connectivity"]);
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
            ALSLog(ALLoggerSeverityError, @"api error : %@ - %@",tag,errorString);
            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil,[self errorWithDescription:message_SomethingWentWrong]);
            });
            return;
        }

        if (data == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                reponseCompletion(nil,[self errorWithDescription:message_SomethingWentWrong]);
            });
            ALSLog(ALLoggerSeverityError, @"api error - %@",tag);
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
                    reponseCompletion(nil,[self errorWithDescription:message_SomethingWentWrong]);
                });
                ALSLog(ALLoggerSeverityError, @"api error - %@",tag);
                return;
            }

            if (decryptedData.bytes) {

                NSString *dataToString = [NSString stringWithUTF8String:[decryptedData bytes]];

                data = [dataToString dataUsingEncoding:NSUTF8StringEncoding];

            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    reponseCompletion(nil,[self errorWithDescription:message_SomethingWentWrong]);
                });
                ALSLog(ALLoggerSeverityError, @"api error - %@",tag);
                return;
            }
        }

        if ([tag isEqualToString:@"CREATE FILE URL"] ||
            [tag isEqualToString:@"IMAGE POSTING"]) {
            jsonResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            /*TODO: Right now server is returning server's Error with tag <html>.
             it should be proper jason response with errocodes.
             We need to remove this check once fix will be done in server.*/

            NSError *error = [self checkForServerError:jsonResponse];
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
                NSError *error = [self checkForServerError:responseString];
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        reponseCompletion(nil, error);
                    });
                    return;
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        reponseCompletion(responseString,nil);
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


- (void)authenticateAndProcessRequest:(NSMutableURLRequest *)request
                               andTag:(NSString *)tag
                WithCompletionHandler:(void (^)(id, NSError *))completion {

    [self authenticateRequest:request WithCompletion:^(NSMutableURLRequest *urlRequest, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        [self processRequest:urlRequest
                      andTag:tag
       WithCompletionHandler:^(id jsonResponse, NSError *error) {
            completion(jsonResponse, error);
        }];
    }];
}

- (void)authenticateRequest:(NSMutableURLRequest *)request
             WithCompletion:(void (^)(NSMutableURLRequest *urlRequest, NSError *error)) completion {

    [self.authService validateAuthTokenAndRefreshWithCompletion:^(NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        NSMutableURLRequest *urlRequest = request;
        NSString *authToken = [ALUserDefaultsHandler getAuthToken];
        if (authToken) {
            [urlRequest addValue:[ALUserDefaultsHandler getAuthToken] forHTTPHeaderField:@"X-Authorization"];
        }
        completion(urlRequest, nil);
    }];
}

- (NSError *)errorWithDescription:(NSString *)reason {
    return [NSError errorWithDomain:@"Applozic" code:1 userInfo:[NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey]];
}

- (NSError *)checkForServerError:(NSString *)response {
    if ([response hasPrefix:@"<html>"] || [response isEqualToString:[@"error" uppercaseString]]) {
        NSError *error = [NSError errorWithDomain:@"Internal Error" code:500 userInfo:nil];
        return error;
    }
    return NULL;
}

@end

