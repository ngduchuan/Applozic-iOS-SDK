//
//  ALChannelFeedResponse.m
//  Applozic
//
//  Created by Nitin on 20/10/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import "ALChannelCreateResponse.h"
#import "ALChannelFeedResponse.h"
#import "ALContactDBService.h"
#import "ALUserDetail.h"

@implementation ALChannelFeedResponse


- (instancetype)initWithJSONString:(NSString *)JSONString {
    self = [super initWithJSONString:JSONString];
    
    if ([super.status isEqualToString: AL_RESPONSE_SUCCESS]) {
        NSDictionary *JSONDictionary = [JSONString valueForKey:@"response"];
        self.alChannel = [[ALChannel alloc] initWithDictonary:JSONDictionary];
        [self parseUserDetails:[[NSMutableArray alloc] initWithArray:[JSONDictionary objectForKey:@"users"]]];
    }
    return self;
}

- (void)parseUserDetails:(NSMutableArray *)userDetailJsonArray {
    
    for (NSDictionary *JSONDictionaryObject in userDetailJsonArray) {
        ALUserDetail *userDetail = [[ALUserDetail alloc] initWithDictonary:JSONDictionaryObject];
        userDetail.unreadCount = 0;
        ALContactDBService *contactDBService = [ALContactDBService new];
        [contactDBService updateUserDetail: userDetail];
    }
}


@end
