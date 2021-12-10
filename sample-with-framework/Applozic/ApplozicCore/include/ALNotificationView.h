//
//  ALNotificationView.h
//  ChatApp
//
//  Created by Devashish on 06/10/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ApplozicCore.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALNotificationView` class is used for showing local notification and it is used in Applozic UI.
@interface ALNotificationView : UILabel

/// Sets in `-[ALNotificationView initWithAlMessage:withAlertMessage]` method and the receiver userId for which notification to show otherwise it will be nil.
@property (retain ,nonatomic) NSString * _Nullable contactId;

/// Sets in `-[ALNotificationView initWithAlMessage:withAlertMessage]` method and the groupId for which the notification to show otherwise it will be nil
@property (retain, nonatomic) NSNumber * _Nullable groupId;

/// Sets in `-[ALNotificationView initWithAlMessage:withAlertMessage]` method and the conversationId is of topic-based chat otherwise it will be nil.
@property (retain, nonatomic) NSNumber * _Nullable conversationId;

/// Sets in `-[ALNotificationView initWithAlMessage:withAlertMessage]` method it will have `ALMessage` object.
@property (retain, nonatomic) ALMessage *message;

/// Get the `ALNotificationView` object with `ALMessage` and alert message for showing a notification.
/// @param message An `ALMessage` object with message details.
/// @param alertMessage An alert message to display.
- (instancetype)initWithAlMessage:(ALMessage *)message withAlertMessage:(NSString * _Nullable)alertMessage;

/// Shows local notification and handler for the tap event for notification.
/// @param handler The handler will be called once the tap on the local notification.
- (void)showNativeNotificationWithcompletionHandler:(void (^)(BOOL))handler;

/// Showing the default notification message for member left from the channel.
- (void)showGroupLeftMessage;

/// Show default no Internet Connectivity message.
- (void)noDataConnectionNotificationView;

/// Showing information notification with given notification alert text.
/// @param message An message text to show in notification.
+ (void)showNotification:(NSString *)message;

/// Shows promotional notification.
/// @param text An text to show in local notification.
+ (void)showPromotionalNotifications:(NSString *)text;

/// Showing information notification.
/// @param text An message text to show in notification.
+ (void)showLocalNotification:(NSString *)text DEPRECATED_MSG_ATTRIBUTE("Use showNotification: instead");

@end

NS_ASSUME_NONNULL_END
