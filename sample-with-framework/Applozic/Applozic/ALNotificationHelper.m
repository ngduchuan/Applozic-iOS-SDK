//
//  ALNotificationHelper.m
//  Applozic
//
//  Created by apple on 19/12/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALNotificationHelper.h"
#import "ALApplozicSettings.h"

@implementation ALNotificationHelper


-(BOOL)isApplozicViewControllerOnTop {

    ALPushAssist * alPushAssist = [[ALPushAssist alloc]init];
    NSString* topViewControllerName = NSStringFromClass(alPushAssist.topViewController.class);
    return ([topViewControllerName hasPrefix:@"AL"]
            || [topViewControllerName hasPrefix:@"Applozic"]
            || [topViewControllerName isEqualToString:@"CNContactPickerViewController"]
            || [topViewControllerName isEqualToString:@"CAMImagePickerCameraViewController"]);
}

-(void)handlerNotificationClick:(NSString *)contactId withGroupId:(NSNumber *)groupID withConversationId:(NSNumber *)conversationId notificationTapActionDisable:(BOOL)isTapActionDisabled {

    if (isTapActionDisabled) {
        ALSLog(ALLoggerSeverityInfo, @"Notification tap is disabled");
        return;
    }

    self.isTapActionDisabled = isTapActionDisabled;

    if (groupID != nil) {
        self.groupId = groupID;
    } else if (contactId != nil) {
        self.userId = contactId;
        self.conversationId = conversationId;
    }

    ALPushAssist * alPushAssist = [[ALPushAssist alloc]init];

    if ([alPushAssist.topViewController isKindOfClass:[ALMessagesViewController class]]) {

        ALMessagesViewController* messagesViewController = (ALMessagesViewController*)alPushAssist.topViewController;

        messagesViewController.channelKey = self.groupId;
        messagesViewController.userIdToLaunch = self.userId;
        messagesViewController.conversationId = self.conversationId;

        [messagesViewController createDetailChatViewControllerWithUserId:messagesViewController.userIdToLaunch withGroupId:messagesViewController.channelKey withConversationId:messagesViewController.conversationId];

    } else if ([alPushAssist.topViewController isKindOfClass:[ALChatViewController class]]) {

        ALChatViewController * viewController = (ALChatViewController*)alPushAssist.topViewController;
        [viewController refreshViewOnNotificationTap:self.userId withChannelKey:self.groupId withConversationId:self.conversationId];

    } else {
        [self findViewController];
    }

}

-(void) findViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        ALPushAssist *pushAssit = [[ALPushAssist alloc] init];
        [self checkControllerAndDismissIfRequired:pushAssit.topViewController withCompletion:^(BOOL handleClick) {
            if(handleClick) {
                [self handlerNotificationClick:self.userId withGroupId:self.groupId withConversationId:self.conversationId notificationTapActionDisable:self.isTapActionDisabled];
            }
        }];

    });
}

-(void)checkControllerAndDismissIfRequired:(UIViewController*)viewController withCompletion:(void(^)(BOOL handleClick))completion {

    if(![self isApplozicViewControllerOnTop]){
        completion(NO);
    }

    if ([[ALMessagesViewController class] isKindOfClass:NSClassFromString(@"ALMessagesViewController")]
        || [[ALMessagesViewController class] isKindOfClass: NSClassFromString(@"ALChatViewController")]) {
        completion(YES);
        return;
    }

    if (viewController.navigationController != nil
        && [viewController.navigationController popViewControllerAnimated:NO] != nil) {
        completion(YES);
        return;
    }
    [viewController dismissViewControllerAnimated:NO completion:^ {
        completion(YES);
    }];
}
@end
