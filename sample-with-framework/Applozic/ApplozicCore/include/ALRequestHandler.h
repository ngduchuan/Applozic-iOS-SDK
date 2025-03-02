//
//  ALRequestHandler.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALRequestHandler` is used for creating a request of GET, POST, or PATCH.
@interface ALRequestHandler : NSObject

/// Creates an GET URL request for calling to Applozic server.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @note Internal API request method don't need to call from outside.
+ (NSMutableURLRequest *)createGETRequestWithUrlString:(NSString *)urlString
                                           paramString:(NSString * _Nullable)paramString;

/// Creates an GET URL request with ofUserId to call the Applozic server on behalf of some user.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @param userId Pass the userId that you want to call the API URL request.
/// @note Internal API request method don't need to call from outside.
+ (NSMutableURLRequest *)createGETRequestWithUrlString:(NSString *)urlString
                                           paramString:(NSString * _Nullable)paramString
                                              ofUserId:(NSString * _Nullable)userId;

/// Creates an POST URL request with ofUserId to call the Applozic server on behalf of some user.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @param userId Pass the userId that you want to call the API URL request.
/// @note Internal API request method don't need to call from outside.
+ (NSMutableURLRequest *)createPOSTRequestWithUrlString:(NSString *)urlString
                                            paramString:(NSString * _Nullable)paramString
                                               ofUserId:(NSString * _Nullable)userId;

/// Creates an POST URL request for calling to Applozic server.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @note Internal API request method don't need to call from outside.
+ (NSMutableURLRequest *)createPOSTRequestWithUrlString:(NSString *)urlString
                                            paramString:(NSString * _Nullable)paramString;

/// Creates an GET URL request for calling to Applozic server without header.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @note Internal API request method don't need to call from outside.
+ (NSMutableURLRequest *)createGETRequestWithUrlStringWithoutHeader:(NSString *)urlString
                                                        paramString:(NSString * _Nullable)paramString;

/// Creates an PATCH URL request for calling to Applozic server.
/// @param urlString API request URL string.
/// @param paramString Pass the parameter for URL request.
/// @note Internal API request method don't need to call from outside.
+ (NSMutableURLRequest *)createPatchRequestWithUrlString:(NSString *)urlString
                                             paramString:(NSString * _Nullable)paramString;

@end

NS_ASSUME_NONNULL_END
