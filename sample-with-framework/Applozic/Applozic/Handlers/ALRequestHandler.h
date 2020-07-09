//
//  ALRequestHandler.h
//  ALChat
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+Utility.h"

@interface ALRequestHandler : NSObject

+(NSMutableURLRequest *) createGETRequestWithUrlString:(NSString *) urlString paramString:(NSString *) paramString;

+(NSMutableURLRequest *) createGETRequestWithUrlString:(NSString *) urlString paramString:(NSString *) paramString ofUserId:(NSString *)userId;

+(void ) createPOSTRequestWithUrlString:(NSString *) urlString paramString:(NSString *) paramString ofUserId:(NSString *)userId withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion;

+(void) createPOSTRequestWithUrlString:(NSString *) urlString paramString:(NSString *) paramString withCompletion:(void(^)(NSMutableURLRequest *theRequest, NSError *error))completion;

+(NSMutableURLRequest *) createGETRequestWithUrlStringWithoutHeader:(NSString *) urlString paramString:(NSString *) paramString;

+(NSMutableURLRequest *) createPatchRequestWithUrlString:(NSString *) urlString paramString:(NSString *) paramString;

+(NSMutableURLRequest *) createPOSTRequestWithUrl:(NSString *)urlString
                                      paramString:(NSString *)paramString
                                    withAuthToken: (NSString *)authToken
                                         ofUserId:(NSString *)userId;
@end
