//
//  ALAttachmentService.h
//  Applozic
//
//  Created by sunil on 25/09/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALHTTPManager.h"
#import "ALMessage.h"
#import "ALMessageDBService.h"
#import "ALMessageService.h"
#import "ALRealTimeUpdate.h"
#import "ApplozicClient.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALAttachmentService` class has methods for sending and downloading an attachment, downloading a thumbnail.
@interface ALAttachmentService : NSObject

/// This delegate is used for listening attachment upload or download events.
@property (nonatomic, strong) id<ApplozicAttachmentDelegate>attachmentProgressDelegate;

/// `ApplozicUpdatesDelegate` delegate is used for real time delegate events for message.
@property (nonatomic, weak) id<ApplozicUpdatesDelegate> delegate;

/// Instance method of `ALAttachmentService`.
+ (ALAttachmentService *)sharedInstance;

/// Sends an attachment message in chat.
/// @param attachmentMessage Pass the `ALMessage` object.
/// @param delegate Sets the `ApplozicUpdatesDelegate` for real time update of the message status like sent.
/// @param attachmentProgressDelegate Sets the `ApplozicAttachmentDelegate` for the upload and download events.
- (void)sendMessageWithAttachment:(ALMessage *)attachmentMessage
                     withDelegate:(id<ApplozicUpdatesDelegate>)delegate
           withAttachmentDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate;

/// Downloads an attachment for given `ALMessage` object.
/// @param message Pass the `ALMessage` object.
/// @param attachmentProgressDelegate Sets the `ApplozicAttachmentDelegate` for real-time updates for download events.
- (void)downloadMessageAttachment:(ALMessage *)message withDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate;

/// Downloads an thumbnail image for attachment.
/// @param message Pass the `ALMessage` object.
/// @param attachmentProgressDelegate Sets the `ApplozicAttachmentDelegate` for real-time updates for download events.
- (void)downloadImageThumbnail:(ALMessage *)message withDelegate:(id<ApplozicAttachmentDelegate>)attachmentProgressDelegate;

@end

NS_ASSUME_NONNULL_END
