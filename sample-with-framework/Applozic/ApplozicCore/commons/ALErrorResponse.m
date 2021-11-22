//
//  ALErrorResponse.m
//  ApplozicCore
//
//  Created by Sunil on 17/11/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import "ALErrorResponse.h"

@implementation ALErrorResponse

@synthesize description;

- (id)initWithDictionary:(NSDictionary *)responseDictionary {
    self = [super init];
    if (self) {
        self.errorDescription = [responseDictionary valueForKey:@"description"];
        self.displayMessage = [responseDictionary valueForKey:@"displayMessage"];
        self.errorCode = [responseDictionary valueForKey:@"errorCode"];
    }
    return self;
}

-(NSString *)errorDescriptionMessage {

    if (!self.errorCode &&
        !self.errorDescription) {
        return nil;
    }
    return [[NSString alloc] initWithFormat:@"Error %@ : %@", self.errorCode, self.errorDescription];
}

@end
