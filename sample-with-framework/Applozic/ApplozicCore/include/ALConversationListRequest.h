//
//  ALConversationListRequest.h
//  ApplozicCore
//
//  Created by Sunil on 08/04/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALConversationListRequest` is used for creating a request in fetching a messages from core database based on the start time stamp or end time stamp.
@interface ALConversationListRequest : NSObject

/// The start time can be passed in case if you want to load the new messages based on start time.
@property(nonatomic,retain) NSNumber * _Nullable startTimeStamp;

/// The end time can be passed in case if you want to load the older messages.
@property(nonatomic,retain) NSNumber * _Nullable endTimeStamp;

@end

NS_ASSUME_NONNULL_END
