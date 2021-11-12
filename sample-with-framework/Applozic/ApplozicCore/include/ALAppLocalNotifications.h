//
//  ALAppLocalNotifications.h
//  Applozic
//
//  Created by devashish on 07/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALMessageService.h"
#import "ALReachability.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALAppLocalNotifications : NSObject

@property(strong) ALReachability * _Nullable googleReach;
@property(strong) ALReachability * _Nullable localWiFiReach;
@property(strong) ALReachability * _Nullable internetConnectionReach;
@property (nonatomic) BOOL flag;

+ (ALAppLocalNotifications *)appLocalNotificationHandler;
- (void)dataConnectionNotificationHandler;
- (void)reachabilityChanged:(NSNotification *)note;
- (void)proactivelyConnectMQTT;
- (void)proactivelyDisconnectMQTT;

@end
NS_ASSUME_NONNULL_END
