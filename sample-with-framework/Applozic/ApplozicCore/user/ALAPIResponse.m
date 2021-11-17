
//  ALAPIResponse.m
//  Applozic
//
//  Created by devashish on 19/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import "ALLogger.h"

NSString *const AL_RESPONSE_SUCCESS = @"success";
NSString *const AL_RESPONSE_ERROR = @"error";

@implementation ALAPIResponse

- (id)initWithJSONString:(NSString *)JSONString {
    [self parseMessage:JSONString];
    return self;
}

- (void)parseMessage:(id)jsonResponse {
    self.status = [self getStringFromJsonValue:jsonResponse[@"status"]];
    self.generatedAt = [self getNSNumberFromJsonValue:jsonResponse[@"generatedAt"]];
    self.response =  [jsonResponse valueForKey:@"response"];
    self.actualresponse = jsonResponse;
    ALSLog(ALLoggerSeverityInfo, @"Response status is (%@) and generated At time is (%@)",self.status, self.generatedAt);
}

@end
