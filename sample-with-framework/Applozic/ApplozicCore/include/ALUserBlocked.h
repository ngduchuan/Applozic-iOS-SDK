//
//  ALUserBlocked.h
//  Applozic
//
//  Created by devashish on 10/03/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/// `ALUserBlocked` class is used for block and unblock details of the user.
@interface ALUserBlocked : NSObject

/// Generated Id of the stored in data base.
@property (nonatomic, strong) NSString *id;

/// Blocked to userId of the user.
@property (nonatomic, strong) NSString *blockedTo;

/// Blocked by userId of the user.
@property (nonatomic, strong) NSString *blockedBy;

/// App-ID of the user.
@property (nonatomic, strong) NSString *applicationKey;

/// Response created at time stamp.
@property (nonatomic, strong) NSNumber *createdAtTime;

/// Response updated at time stamp.
@property (nonatomic, strong) NSNumber *updatedAtTime;

/// YES in case of user is blocked by you otherwise it will be NO in case of you have not blocked..
@property (nonatomic) BOOL userBlocked;

/// YES in case of user blocked you otherwise it will be NO in case of user not blocked you.
@property (nonatomic) BOOL userblockedBy;

@end
