//
//  ALNotificationView.h
//  ChatApp
//
//  Created by Devashish on 06/10/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApplozicCore.h"

/// `ALNotificationView` class is used for showing local notification and it is used in Applozic UI.
@interface ALNotificationView : UILabel

/// This is set in initWithAlMessage  the userId for which notification to show otherwise it will be nil.
@property (retain ,nonatomic) NSString *contactId;

/// This is set in initWithAlMessage the groupId for which the notification to show otherwise it will be nil
@property (retain, nonatomic) NSNumber *groupId;

/// This is set in initWithAlMessage the conversation in case of topic based chat otherwise it will be nil.
@property (retain, nonatomic) NSNumber *conversationId;

/// This is set in initWithAlMessage will have `ALMessage` object.
@property (retain, nonatomic) ALMessage *alMessageObject;

/// Use this method to init the notification `ALNotificationView` and this data is used in showing the noticiation.
/// @param alMessage Pass the the `ALMessage` object with message details.
/// @param alertMessage Pass the alert message to display.
- (instancetype)initWithAlMessage:(ALMessage *)alMessage withAlertMessage: (NSString *)alertMessage;

/// Use this method to show the notification and handle the tap event for notification.
/// @param handler The handler will be called once the tap on the local notification.
- (void)showNativeNotificationWithcompletionHandler:(void (^)(BOOL))handler;

/// This method is used for showing the default notification message for member left from channel or group.
- (void)showGroupLeftMessage;

/// This method is used for showing information notification.
/// @param text Pass the message text to show in notification
+ (void)showLocalNotification:(NSString *)text DEPRECATED_MSG_ATTRIBUTE("Use showNotification: instead");

/// This method will show No Internet Connectivity message.
- (void)noDataConnectionNotificationView;

/// This method is used for showing information notification.
/// @param message Pass the message text to show in notification.
+ (void)showNotification:(NSString *)message;

/// This method is used for showing Promotional notification.
/// @param text Pass the text to show in local notification.
+ (void)showPromotionalNotifications:(NSString *)text;


@end
