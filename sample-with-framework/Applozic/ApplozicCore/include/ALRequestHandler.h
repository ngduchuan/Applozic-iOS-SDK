//
//  ALRequestHandler.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>

/// `ALRequestHandler` is used for creating a request of GET, POST, or PATCH.
@interface ALRequestHandler : NSObject

/// Create an GET URL request for calling to Applozic server.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createGETRequestWithUrlString:(NSString *)urlString
                      paramString:(NSString *)paramString;

/// Create an GET URL request with ofUserId to call the Applozic server on behalf of some user.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @param userId Pass the userId that you want to call the API URL request.
+ (NSMutableURLRequest *)createGETRequestWithUrlString:(NSString *)urlString
                      paramString:(NSString *)paramString
                       ofUserId:(NSString *)userId;

/// Create an POST URL request with ofUserId to call the Applozic server on behalf of some user.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @param userId Pass the userId that you want to call the API URL request.
+ (NSMutableURLRequest *)createPOSTRequestWithUrlString:(NSString *)urlString
                      paramString:(NSString *)paramString
                        ofUserId:(NSString *)userId;

/// Create an POST URL request for calling to Applozic server.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createPOSTRequestWithUrlString:(NSString *)urlString
                      paramString:(NSString *)paramString;

/// Create an GET URL request for calling to Applozic server without header.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createGETRequestWithUrlStringWithoutHeader:(NSString *)urlString
                            paramString:(NSString *)paramString;

/// Create an PATCH URL request for calling to Applozic server.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createPatchRequestWithUrlString:(NSString *)urlString
                       paramString:(NSString *)paramString;

@end
