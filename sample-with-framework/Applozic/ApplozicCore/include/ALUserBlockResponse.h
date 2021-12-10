//
//  ALUserBlockResponse.h
//  Applozic
//
//  Created by devashish on 07/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALAPIResponse.h"
#import "ALUserBlocked.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALUserBlockResponse : ALAPIResponse

@property(nonatomic, strong) NSMutableArray * _Nullable blockedToUserList;
@property(nonatomic, strong) NSMutableArray * _Nullable blockedByList;

@property(nonatomic, strong) NSMutableArray <ALUserBlocked *> * _Nullable blockedUserList;
@property(nonatomic, strong) NSMutableArray <ALUserBlocked *> * _Nullable blockByUserList;

- (instancetype)initWithJSONString:(NSString *)JSONString;

@end

NS_ASSUME_NONNULL_END
