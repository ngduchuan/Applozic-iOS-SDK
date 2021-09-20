//
//  ALMuteRequest.h
//  Applozic
//
//  Created by Adarsh Kumar Mishra on 1/12/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import "ALJson.h"

/// `ALMuteRequest` is used for creating a mute request for one-to-one or channel conversation mute or unmute.
@interface ALMuteRequest : ALJson

/// Set the userId in case of one-to-one mute or unmute request.
@property (nonatomic, strong) NSString *userId;
/// Set the Group id in case of channel or group mute or unmute request.
@property (nonatomic, strong) NSNumber *id;
/// Client Group id in case if you have your client group id is set during create channel then you can use that.
@property (nonatomic, strong) NSString *clientGroupId;
/// Time Interval for which notification has been disabled.
@property (nonatomic, strong) NSNumber *notificationAfterTime;

@end
