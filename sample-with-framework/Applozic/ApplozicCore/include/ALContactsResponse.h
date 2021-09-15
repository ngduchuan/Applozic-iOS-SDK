//
//  ALContactsResponse.h
//  Applozic
//
//  Created by devashish on 25/04/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALJson.h"

/// `ALContactsResponse` class is used for parsing the user details response JSON.
@interface ALContactsResponse : ALJson

/// <#Description#>
@property (nonatomic, strong) NSNumber *lastFetchTime;

/// <#Description#>
@property (nonatomic, strong) NSNumber *totalUnreadCount;

@property (nonatomic, strong) NSMutableArray *userDetailList;

@end
