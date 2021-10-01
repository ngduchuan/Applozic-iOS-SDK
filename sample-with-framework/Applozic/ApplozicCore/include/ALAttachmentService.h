//
//  ALAttachmentService.h
//  Applozic
//
//  Created by sunil on 25/09/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessageDBService.h"
#import "ALMessage.h"
#import "ALMessageService.h"
#import "ALRealTimeUpdate.h"
#import "ApplozicClient.h"
#import "ALHTTPManager.h"

NS_ASSUME_NONNULL_BEGIN

/// `ALAttachmentService` class has methods for sending and downloading an attachment, downloading a thumbnail.
@interface ALAttachmentService : NSObject

/// This delegate is used for listening attachment upload or download events.
@property (nonatomic, strong) id<ApplozicAttachmentDelegate>attachmentProgressDelegate;

/// `ApplozicUpdatesDelegate` delegate is used for real time delegate events for message.
@property (nonatomic, weak) id<ApplozicUpdatesDelegate> delegate;

/// Instance method of `ALAttachmentService`.
+ (ALAttachmentService *)sharedInstance;

/// This method is used for sending an attachment message in chat.
/// @param attachmentMessage Pass the `ALMessage` object.
/// @param delegate Set the `ApplozicUpdatesDelegate` for real time update of the message status like sent.
/// @param attachmentProgressDelegate Set the `ApplozicAttachmentDelegate` for the upload and download events.
- (void)sendMessageWithAttachment:(ALMessage *)attachmentMessage
           withDelegate:(id<ApplozicUpdatesDelegate>)delegate
      withAttachmentDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate;

/// This method is used for downloading an attachment message.
/// @param alMessage Pass the `ALMessage` object.
/// @param attachmentProgressDelegate Set the `ApplozicAttachmentDelegate` for real-time updates for download events.
- (void)downloadMessageAttachment:(ALMessage *)alMessage withDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate;

/// This method is used for downloading an thumbnail image.
/// @param alMessage Pass the `ALMessage` object.
/// @param attachmentProgressDelegate Set the `ApplozicAttachmentDelegate` for real-time updates for download events.
- (void)downloadImageThumbnail:(ALMessage *)alMessage withDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate;

@end

NS_ASSUME_NONNULL_END
