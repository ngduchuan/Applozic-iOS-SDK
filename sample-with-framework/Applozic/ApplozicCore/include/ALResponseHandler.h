//
//  ALResponseHandler.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAuthService.h"

/// `ALResponseHandler`used for handling the URL request for calling the server for all the APIs.
///
/// Has methods for processing requests, JWT authenticates a request before processing.
@interface ALResponseHandler : NSObject

/// `ALAuthService` instance method.
@property (nonatomic, strong) ALAuthService *authService;

/// Calling an API without JWT token.
/// @param theRequest Create a URLRequest using `ALRequestHandler`.
/// @param tag An tag of request to identify the request.
/// @param reponseCompletion An complete JSON response otherwise an error describing the request failure.
/// @note Internal API request method don't need to call from outside.
- (void)processRequest:(NSMutableURLRequest *)theRequest
        andTag:(NSString *)tag
 WithCompletionHandler:(void(^)(id theJson , NSError *theError))reponseCompletion;

/// Authenticate to Applozic sever by JWT token validation and proccess the request for API call.
/// @param theRequest Create a URLRequest using `ALRequestHandler`.
/// @param tag Pass the tag for request to identify the request.
/// @param completion An complete JSON response otherwise an error describing the Authenticate failure.
/// @note Internal API request method don't need to call from outside.
- (void)authenticateAndProcessRequest:(NSMutableURLRequest *)theRequest
                andTag:(NSString *)tag
        WithCompletionHandler:(void (^)(id, NSError *))completion;


/// Authenticate to Applozic sever for JWT token and will have the mutable URL request updated with JWT Token for calling the Applozic sever.
/// @param request Create a URLRequest using `ALRequestHandler`.
/// @param completion Will have `NSMutableURLRequest` if success in generating JWT token otherwise an error describing the Authenticate failure.
/// @note Internal API request method don't need to call from outside.
- (void)authenticateRequest:(NSMutableURLRequest *)request
       WithCompletion:(void (^)(NSMutableURLRequest *urlRequest, NSError *error))completion;

@end
