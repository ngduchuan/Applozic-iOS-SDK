//
//  ALMessageWrapper.h
//  Applozic
//
//  Created by Adarsh Kumar Mishra on 12/14/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ApplozicClient.h"
#import "ALMessage.h"
#import <Foundation/Foundation.h>

@protocol MessageServiceWrapperDelegate <NSObject>

@optional

- (void)updateBytesDownloaded:(NSUInteger)bytesReceived;
- (void)updateBytesUploaded:(NSUInteger)bytesSent;
- (void)uploadDownloadFailed:(ALMessage *)message;
- (void)uploadCompleted:(ALMessage *)updatedMessage;
- (void)DownloadCompleted:(ALMessage *)message;

@end

@interface ALMessageServiceWrapper : NSObject

@property (strong, nonatomic) id <MessageServiceWrapperDelegate> messageServiceDelegate;

- (void)sendTextMessage:(NSString *)text andtoContact:(NSString *)toContactId;

- (void)sendTextMessage:(NSString *)messageText andtoContact:(NSString *)contactId orGroupId:(NSNumber *)channelKey;

- (void)sendMessage:(ALMessage *)message
withAttachmentAtLocation:(NSString *)attachmentLocalPath
andWithStatusDelegate:(id)statusDelegate
     andContentType:(short)contentype;

- (void)downloadMessageAttachment:(ALMessage *)message;

- (ALMessage *)createMessageEntityOfContentType:(int)contentType
                                       toSendTo:(NSString *)to
                                       withText:(NSString *)text;

@end
