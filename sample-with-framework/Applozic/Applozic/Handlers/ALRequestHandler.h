//
//  ALRequestHandler.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+Utility.h"

@interface ALRequestHandler : NSObject

+(void) createGETRequestWithUrlString:(NSString *)urlString
                          paramString:(NSString *)paramString
                       withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion;

+(void) createGETRequestWithUrlString:(NSString *)urlString
                          paramString:(NSString *)paramString
                             ofUserId:(NSString *)userId
                       withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion;

+(void ) createPOSTRequestWithUrlString:(NSString *)urlString
                            paramString:(NSString *)paramString
                               ofUserId:(NSString *)userId
                         withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion;

+(void) createPOSTRequestWithUrlString:(NSString *)urlString
                           paramString:(NSString *)paramString
                        withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion;

+(NSMutableURLRequest *) createGETRequestWithUrlStringWithoutHeader:(NSString *)urlString
                                                        paramString:(NSString *)paramString;

+(void) createPatchRequestWithUrlString:(NSString *)urlString
                                             paramString:(NSString *)paramString withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion;

+(NSMutableURLRequest *) createPOSTRequestWithUrl:(NSString *)urlString
                                      paramString:(NSString *)paramString
                                    withAuthToken:(NSString *)authToken
                                         ofUserId:(NSString *)userId;
@end
