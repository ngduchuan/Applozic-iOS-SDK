//
//  ALNotificationView.m
//  ChatApp
//
//  Created by Devashish on 06/10/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALNotificationView.h"

@implementation ALNotificationView


/*********************
 GROUP_NAME
 CONTACT_NAME: MESSAGE
 *********************
 
 *********************
 CONTACT_NAME
 MESSAGE
 *********************/


- (instancetype)initWithAlMessage:(ALMessage *)message withAlertMessage:(NSString *)alertMessage {
    self = [super init];
    self.text =[self getNotificationText:message];
    self.textColor = [UIColor whiteColor];
    self.textAlignment = NSTextAlignmentCenter;
    self.layer.cornerRadius = 0;
    self.userInteractionEnabled = YES;
    self.contactId = message.contactIds;
    self.groupId = message.groupId;
    self.conversationId = message.conversationId;
    self.message = message;
    return self;
}

- (NSString *)getNotificationText:(ALMessage *)message {
    
    if (message.contentType == ALMESSAGE_CONTENT_LOCATION) {
        return NSLocalizedStringWithDefaultValue(@"shareadLocationText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Shared a Location", @"") ;
    } else if (message.contentType == ALMESSAGE_CONTENT_VCARD) {
        return NSLocalizedStringWithDefaultValue(@"shareadContactText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Shared a Contact", @"");
    } else if (message.contentType == ALMESSAGE_CONTENT_CAMERA_RECORDING) {
        return NSLocalizedStringWithDefaultValue(@"shareadVideoText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Shared a Video", @"");
    } else if (message.contentType == ALMESSAGE_CONTENT_AUDIO) {
        return NSLocalizedStringWithDefaultValue(@"shareadAudioText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Shared an Audio", @"");
    } else if (message.contentType == AV_CALL_MESSAGE) {
        return [message getVOIPMessageText];
    } else if (message.contentType == ALMESSAGE_CONTENT_ATTACHMENT ||
               [message.message isEqualToString:@""] ||
               message.fileMeta != NULL) {
        return NSLocalizedStringWithDefaultValue(@"shareadAttachmentText", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], @"Shared an Attachment", @"");
    } else {
        return message.message;
    }
}

- (void)customizeMessageView:(TSMessageView *)messageView {
    messageView.alpha = 0.4;
    messageView.backgroundColor=[UIColor blackColor];
}

#pragma mark- Our SDK views notification
//=======================================

- (void)showNativeNotificationWithcompletionHandler:(void (^)(BOOL))handler {
    if (self.groupId != nil) {
        [[ALChannelService new] getChannelInformationByResponse:self.groupId
                                             orClientChannelKey:nil
                                                 withCompletion:^(NSError *error,
                                                                  ALChannel *channel,
                                                                  ALChannelFeedResponse *channelResponse) {

            if (error ||
                !channel) {
                handler(NO);
                return;
            }

            [self buildAndShowNotificationWithcompletionHandler:^(BOOL response) {
                handler(response);
            }];
        }];
    } else {
        [self buildAndShowNotificationWithcompletionHandler:^(BOOL response) {
            handler(response);
        }];
    }
}

- (void)buildAndShowNotificationWithcompletionHandler:(void (^)(BOOL))handler {

    if ([self.message isNotificationDisabled]) {
        return;
    }
    
    NSString *title; // Title of Notification Banner (Display Name or Group Name)
    NSString *subtitle = self.text; //Message to be shown

    ALPushAssist *top = [[ALPushAssist alloc] init];

    ALContactDBService * contactDbService = [[ALContactDBService alloc] init];
    ALContact *contact = [contactDbService loadContactByKey:@"userId" value:self.contactId];

    ALChannel *channel = nil;
    ALChannelDBService *channelDbService = [[ALChannelDBService alloc] init];

    if (self.groupId && self.groupId.intValue != 0) {
        NSString *contactName;
        NSString *groupName;

        channel = [channelDbService loadChannelByKey:self.groupId];
        contact.userId = (contact.userId != nil ? contact.userId:@"");

        groupName = [NSString stringWithFormat:@"%@",(channel.name != nil ? channel.name : self.groupId)];

        if (channel.type == GROUP_OF_TWO) {
            ALContact *groupContact = [contactDbService loadContactByKey:@"userId" value:[channel getReceiverIdInGroupOfTwo]];
            groupName = [groupContact getDisplayName];
        }

        NSArray *notificationComponents = [contact.getDisplayName componentsSeparatedByString:@":"];
        if (notificationComponents.count > 1) {
            contactName = [[contactDbService loadContactByKey:@"userId" value:[notificationComponents lastObject]] getDisplayName];
        } else {
            contactName = contact.getDisplayName;
        }

        if (self.message.contentType == ALMESSAGE_CHANNEL_NOTIFICATION) {
            title = self.text;
            subtitle = @"";
        } else {
            title = groupName;
            subtitle = [NSString stringWithFormat:@"%@:%@",contactName,subtitle];
        }
    } else {
        title = contact.getDisplayName;
        subtitle = self.text;
    }

    // ** Attachment ** //
    if (self.message.contentType == ALMESSAGE_CONTENT_LOCATION) {
        subtitle = [NSString stringWithFormat:@"Shared location"];
    }

    subtitle = (subtitle.length > 20) ? [NSString stringWithFormat:@"%@...",[subtitle substringToIndex:17]] : subtitle;

    UIImage *appIcon = [UIImage imageNamed: [[[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"] objectAtIndex:0]];

    [[TSMessageView appearance] setTitleFont:[UIFont boldSystemFontOfSize:17]];
    [[TSMessageView appearance] setContentFont:[UIFont systemFontOfSize:13]];
    [[TSMessageView appearance] setTitleFont:[UIFont fontWithName:@"Helvetica Neue" size:18.0]];
    [[TSMessageView appearance] setContentFont:[UIFont fontWithName:@"Helvetica Neue" size:14]];
    [[TSMessageView appearance] setTitleTextColor:[UIColor whiteColor]];
    [[TSMessageView appearance] setContentTextColor:[UIColor whiteColor]];


    [TSMessage showNotificationInViewController:top.topViewController
                                          title:title
                                       subtitle:subtitle
                                          image:appIcon
                                           type:TSMessageNotificationTypeMessage
                                       duration:1.75
                                       callback:
     ^(void){
        handler(true);
    }
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                           canBeDismissedByUser:YES];
}

- (void)showGroupLeftMessage {
    [[TSMessageView appearance] setTitleTextColor:[UIColor whiteColor]];
    [TSMessage showNotificationWithTitle: NSLocalizedStringWithDefaultValue(@"youHaveLeftGroupMesasge", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"You have left this group", @"") type:TSMessageNotificationTypeWarning];
}

- (void)noDataConnectionNotificationView {
    [[TSMessageView appearance] setTitleTextColor:[UIColor whiteColor]];
    [TSMessage showNotificationWithTitle: NSLocalizedStringWithDefaultValue(@"noInternetMessage", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"No Internet Connectivity", @"")
                                    type:TSMessageNotificationTypeWarning];
}

+ (void)showLocalNotification:(NSString *)text {
    [[TSMessageView appearance] setTitleTextColor:[UIColor whiteColor]];
    [TSMessage showNotificationWithTitle:text type:TSMessageNotificationTypeWarning];
}

+ (void)showPromotionalNotifications:(NSString *)text {
    UIImage *appIcon = [UIImage imageNamed:[[[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"] objectAtIndex:0]];
    
    [[TSMessageView appearance] setTitleFont:[UIFont boldSystemFontOfSize:17]];
    [[TSMessageView appearance] setContentFont:[UIFont systemFontOfSize:13]];
    [[TSMessageView appearance] setTitleFont:[UIFont fontWithName:@"Helvetica Neue" size:18.0]];
    [[TSMessageView appearance] setContentFont:[UIFont fontWithName:@"Helvetica Neue" size:14]];
    [[TSMessageView appearance] setTitleTextColor:[UIColor whiteColor]];
    [[TSMessageView appearance] setContentTextColor:[UIColor whiteColor]];
    [[TSMessageView appearance] setDuration:10.0];
    [[TSMessageView appearance] setMessageIcon:appIcon];
    
    [TSMessage showNotificationWithTitle:[ALApplozicSettings getNotificationTitle] subtitle:text
                                    type:TSMessageNotificationTypeMessage];

}

+ (void)showNotification:(NSString *)message {
    [[TSMessageView appearance] setTitleTextColor:[UIColor whiteColor]];
    [TSMessage showNotificationWithTitle:message type:TSMessageNotificationTypeWarning];
}

@end
