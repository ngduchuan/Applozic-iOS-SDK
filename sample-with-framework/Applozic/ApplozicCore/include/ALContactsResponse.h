//
//  ALContactsResponse.h
//  Applozic
//
//  Created by devashish on 25/04/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALJson.h"

NS_ASSUME_NONNULL_BEGIN
/// `ALContactsResponse` class is used for parsing the user details response JSON.
@interface ALContactsResponse : ALJson

/// Last fetched time of contact JSON.
@property (nonatomic, strong) NSNumber * _Nullable lastFetchTime;

/// :nodoc:
@property (nonatomic, strong) NSNumber * _Nullable totalUnreadCount;

/// Array of `ALUserDetail` objects.
@property (nonatomic, strong) NSMutableArray * _Nullable userDetailList;

@end

NS_ASSUME_NONNULL_END
