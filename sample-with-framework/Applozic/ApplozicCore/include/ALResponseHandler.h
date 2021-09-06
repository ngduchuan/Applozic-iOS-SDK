//
//  ALResponseHandler.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAuthService.h"

/// `ALResponseHandler` used for handling the URL request for calling to server for all the APIs.
///
/// Has methods for proccessing request, JWT authenticate request before proccessing.
@interface ALResponseHandler : NSObject

/// `ALAuthService` instance method.
@property (nonatomic, strong) ALAuthService *authService;

/// Used for calling to server for API call without JWT token.
/// @param theRequest Create URLRequest and pass.
/// @param tag Pass the tag for request to identify the request.
/// @param reponseCompletion Will have JSON response or error.
- (void)processRequest:(NSMutableURLRequest *)theRequest
                andTag:(NSString *)tag
 WithCompletionHandler:(void(^)(id theJson , NSError *theError))reponseCompletion;

/// Use this method to authenticate to applozic sever by JWT token validation and proccess the request for API call.
/// @param theRequest Create a URLRequest and pass.
/// @param tag Pass the tag for request to identify the request.
/// @param completion Will have JSON response or error.
- (void)authenticateAndProcessRequest:(NSMutableURLRequest *)theRequest
                               andTag:(NSString *)tag
                WithCompletionHandler:(void (^)(id, NSError *))completion;


/// Use this method to authenticate to applozic sever for JWT token and it will give the NSMutableURLRequest which is updated with JWT Token this request can be used for calling the Applozic sever.
/// @param request Create a URLRequest and pass
/// @param completion Will have `NSMutableURLRequest` if success in genrating JWT token or error.
- (void)authenticateRequest:(NSMutableURLRequest *)request
             WithCompletion:(void (^)(NSMutableURLRequest *urlRequest, NSError *error))completion;

@end
