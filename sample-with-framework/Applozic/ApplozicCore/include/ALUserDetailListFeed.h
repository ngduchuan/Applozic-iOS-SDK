//
//  ALUserDetailListFeed.h
//  Applozic
//
//  Created by Abhishek Thapliyal on 10/13/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALJson.h"

NS_ASSUME_NONNULL_BEGIN

/// `ALUserDetailListFeed` request for fetching User detail.
@interface ALUserDetailListFeed : ALJson

/// Seter method for array of userIds.
@property (nonatomic, strong) NSMutableArray *userIdList;

/// Setter method of array of userIds.
/// @param array Array of string userIds.
- (void)setArray:(NSMutableArray *)array;

@end

NS_ASSUME_NONNULL_END
