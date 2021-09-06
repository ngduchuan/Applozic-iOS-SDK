//
//  ALRequestHandler.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>

/// `ALRequestHandler` is used for creating a request of GET, POST or PATCH.
@interface ALRequestHandler : NSObject

/// Use this method to create GET URL request for calling to Applozic server.
/// @param urlString Pass the Request URL.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createGETRequestWithUrlString:(NSString *)urlString
                                           paramString:(NSString *)paramString;

/// Use this method to create GET URL request with ofUserId to call the for calling to Applozic server on behalf of some user.
/// @param urlString Pass the Request URL.
/// @param paramString Pass the parameter for URL request.
/// @param userId Pass the userId that you want to call the API URL request.
+ (NSMutableURLRequest *)createGETRequestWithUrlString:(NSString *)urlString
                                           paramString:(NSString *)paramString
                                              ofUserId:(NSString *)userId;

/// Use this method to create POST URL request with ofUserId to call the for calling to Applozic server on behalf of some user.
/// @param urlString Pass the Request URL.
/// @param paramString Pass the parameter for URL request.
/// @param userId Pass the userId that you want to call the API URL request.
+ (NSMutableURLRequest *)createPOSTRequestWithUrlString:(NSString *)urlString
                                            paramString:(NSString *)paramString
                                               ofUserId:(NSString *)userId;

/// Use this method to create POST URL request for calling to Applozic server.
/// @param urlString Pass the Request URL.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createPOSTRequestWithUrlString:(NSString *)urlString
                                            paramString:(NSString *)paramString;

/// Use this method to create GET URL request for calling to Applozic server without header.
/// @param urlString Pass the Request URL.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createGETRequestWithUrlStringWithoutHeader:(NSString *)urlString
                                                        paramString:(NSString *)paramString;

/// Use this method to create PATCH URL request for calling to Applozic server.
/// @param urlString Pass the Request URL.
/// @param paramString Pass the parameter for URL request.
+ (NSMutableURLRequest *)createPatchRequestWithUrlString:(NSString *)urlString
                                             paramString:(NSString *)paramString;

@end
