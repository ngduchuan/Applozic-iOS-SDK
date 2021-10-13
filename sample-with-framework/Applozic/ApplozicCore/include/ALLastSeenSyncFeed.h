//
//  ALLastSeenSyncFeed.h
//  Applozic
//
//  Created by Devashish on 19/12/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALJson.h"
#import "ALUserDetail.h"
#import <Foundation/Foundation.h>

/// `ALLastSeenSyncFeed` class is used
@interface ALLastSeenSyncFeed : ALJson

/// Array of the `ALUserDetail` objects.
@property(nonatomic) NSMutableArray <ALUserDetail *> *lastSeenArray;

/// This method is used for parsing the Last seen user status.
/// @param lastSeenResponse Pass the JSON string response.
- (instancetype)initWithJSONString:(NSString *)lastSeenResponse;

/// This method is used for populating the `ALUserDetail` JSON Dictionary.
/// @param jsonString Pass the Array of Dictionary.
- (void)populateLastSeenDetail:(NSMutableArray *)jsonString;

@end
