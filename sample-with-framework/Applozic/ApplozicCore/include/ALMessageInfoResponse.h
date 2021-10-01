//
//  ALMessageInfoResponse.h
//  Applozic
//
//  Created by devashish on 17/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALMessageInfo.h"
#import "ALAPIResponse.h"

/// `ALMessageInfoResponse` class is used for parsing the Message information JSON response.
@interface ALMessageInfoResponse : ALAPIResponse

/// This will be set from `initWithJSONString` can be access array of `ALMessageInfo` objects.
@property(nonatomic, strong) NSMutableArray <ALMessageInfo *> *msgInfoList;

/// This method is used for parsing JSON string response.
/// @param JSONString Pass the JSON string response.
- (instancetype)initWithJSONString:(NSString *)JSONString;

@end
