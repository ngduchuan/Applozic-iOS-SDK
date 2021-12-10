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

NS_ASSUME_NONNULL_BEGIN

/// `ALLastSeenSyncFeed` class is used
@interface ALLastSeenSyncFeed : ALJson

/// Array of the `ALUserDetail` objects.
@property(nonatomic) NSMutableArray <ALUserDetail *> * _Nullable lastSeenArray;

/// This method is used for parsing the Last seen user status.
/// @param lastSeenResponse Pass the JSON string response.
- (instancetype)initWithJSONString:(NSString * _Nullable)lastSeenResponse;

/// This method is used for populating the `ALUserDetail` JSON Dictionary.
/// @param jsonString Pass the Array of Dictionary.
- (void)populateLastSeenDetail:(NSMutableArray * _Nullable)jsonString;

@end

NS_ASSUME_NONNULL_END
