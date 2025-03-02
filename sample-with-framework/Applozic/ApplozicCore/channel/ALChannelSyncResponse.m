//
//  ALChannelSyncResponse.m
//  Applozic
//
//  Created by devashish on 16/02/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALChannelSyncResponse.h"

@implementation ALChannelSyncResponse

- (instancetype)initWithJSONString:(NSString *)JSONString {
    self = [super initWithJSONString:JSONString];
    
    self.alChannelArray = [[NSMutableArray alloc] init];
    
    if ([super.status isEqualToString: AL_RESPONSE_SUCCESS]) {
        NSMutableArray *responseArray = [JSONString valueForKey:@"response"];
        
        for (NSDictionary *JSONDictionaryObject in responseArray) {
            ALChannel *channel = [[ALChannel alloc] initWithDictonary:JSONDictionaryObject];
            [self.alChannelArray addObject:channel];
        }
    }
    return self;
}

@end
