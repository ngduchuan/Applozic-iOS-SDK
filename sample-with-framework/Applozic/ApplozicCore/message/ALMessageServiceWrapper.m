//
//  ALMessageWrapper.m
//  Applozic
//
//  Created by Adarsh Kumar Mishra on 12/14/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALMessageServiceWrapper.h"
#import "ALMessageService.h"
#import "ALMessageDBService.h"
#import "ALConnectionQueueHandler.h"
#import "ALMessageClientService.h"
#include <tgmath.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ALApplozicSettings.h"
#import "ALHTTPManager.h"
#import "ALDownloadTask.h"
#import "ALLogger.h"
#import "ALUtilityClass.h"

@interface ALMessageServiceWrapper  ()<ApplozicAttachmentDelegate>

@end

@implementation ALMessageServiceWrapper

- (void)sendTextMessage:(NSString*)text andtoContact:(NSString*)toContactId {
    
    ALMessage *alMessage = [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_DEFAULT toSendTo:toContactId withText:text];
    
    [[ALMessageService sharedInstance] sendMessages:alMessage withCompletion:^(NSString *message, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"REACH_SEND_ERROR : %@",error);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:alMessage];
    }];
}


- (void)sendTextMessage:(NSString *)messageText andtoContact:(NSString *)contactId orGroupId:(NSNumber *)channelKey {
    
    ALMessage *alMessage = [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_DEFAULT toSendTo:contactId withText:messageText];
    
    alMessage.groupId = channelKey;
    
    [[ALMessageService sharedInstance] sendMessages:alMessage withCompletion:^(NSString *message, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"REACH_SEND_ERROR : %@",error);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:alMessage];
    }];
}

- (void) sendMessage:(ALMessage *)alMessage
withAttachmentAtLocation:(NSString *)attachmentLocalPath
andWithStatusDelegate:(id)statusDelegate
      andContentType:(short)contentype {
    
    //Message Creation
    ALMessage *message = alMessage;
    message.contentType = contentype;
    message.imageFilePath = attachmentLocalPath.lastPathComponent;
    
    //File Meta Creation
    message.fileMeta = [self getFileMetaInfo];
    message.fileMeta.name = [NSString stringWithFormat:@"AUD-5-%@", attachmentLocalPath.lastPathComponent];
    if (alMessage.contactIds) {
        message.fileMeta.name = [NSString stringWithFormat:@"%@-5-%@",alMessage.contactIds, attachmentLocalPath.lastPathComponent];
    }
    NSString *mimeType = [ALUtilityClass fileMIMEType:attachmentLocalPath];
    if (!mimeType) {
        return;
    }

    message.fileMeta.contentType = mimeType;
    if (message.contentType == ALMESSAGE_CONTENT_VCARD) {
        message.fileMeta.contentType = @"text/x-vcard";
    }
    NSData *imageSize = [NSData dataWithContentsOfFile:attachmentLocalPath];
    message.fileMeta.size = [NSString stringWithFormat:@"%lu",(unsigned long)imageSize.length];
    
    //DB Addition
    ALMessageDBService* messageDBService = [[ALMessageDBService alloc] init];
    DB_Message * theMessageEntity = [messageDBService createMessageEntityForDBInsertionWithMessage:message];
    message.msgDBObjectId = [theMessageEntity objectID];
    theMessageEntity.inProgress = [NSNumber numberWithBool:YES];
    theMessageEntity.isUploadFailed = [NSNumber numberWithBool:NO];
    NSError * error =  [[ALDBHandler sharedInstance] saveContext];

    if (self.messageServiceDelegate && error) {
        theMessageEntity.inProgress = [NSNumber numberWithBool:NO];
        theMessageEntity.isUploadFailed = [NSNumber numberWithBool:YES];
        [self.messageServiceDelegate uploadDownloadFailed:alMessage];
        return;
    }

    NSDictionary * userInfo = [alMessage dictionary];
    
    ALMessageClientService * clientService  = [[ALMessageClientService alloc]init];
    [clientService sendPhotoForUserInfo:userInfo withCompletion:^(NSString *message, NSError *error) {
        
        if (error) {
            [self.messageServiceDelegate uploadDownloadFailed:alMessage];
            return;
        }
        ALHTTPManager *httpManager = [[ALHTTPManager alloc]init];
        httpManager.attachmentProgressDelegate = self;
        [httpManager processUploadFileForMessage:[messageDBService createMessageEntity:theMessageEntity] uploadURL:message];
    }];
    
}


- (ALFileMetaInfo *)getFileMetaInfo {
    ALFileMetaInfo *info = [ALFileMetaInfo new];
    
    info.blobKey = nil;
    info.contentType = @"";
    info.createdAtTime = nil;
    info.key = nil;
    info.name = @"";
    info.size = @"";
    info.userKey = @"";
    info.thumbnailUrl = @"";
    info.progressValue = 0;
    
    return info;
}

- (ALMessage *)createMessageEntityOfContentType:(int)contentType
                                       toSendTo:(NSString*)to
                                       withText:(NSString*)text {
    
    ALMessage *alMessage = [ALMessage new];
    
    alMessage.contactIds = to;//1
    alMessage.to = to;//2
    alMessage.message = text;//3
    alMessage.contentType = contentType;//4
    
    alMessage.type = @"5";
    alMessage.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
    alMessage.deviceKey = [ALUserDefaultsHandler getDeviceKeyString ];
    alMessage.sendToDevice = NO;
    alMessage.shared = NO;
    alMessage.fileMeta = nil;
    alMessage.storeOnDevice = NO;
    alMessage.key = [[NSUUID UUID] UUIDString];
    alMessage.delivered = NO;
    alMessage.fileMetaKey = nil;
    
    return alMessage;
}


- (void)downloadMessageAttachment:(ALMessage*)alMessage {

    ALHTTPManager * manager =  [[ALHTTPManager alloc] init];
    manager.attachmentProgressDelegate = self;
    [manager processDownloadForMessage:alMessage isAttachmentDownload:YES];

}

- (void)onDownloadCompleted:(ALMessage *)alMessage {
    [self.messageServiceDelegate DownloadCompleted:alMessage];
}

- (void)onDownloadFailed:(ALMessage *)alMessage {
    [self.messageServiceDelegate uploadDownloadFailed:alMessage];
}

- (void)onUpdateBytesDownloaded:(int64_t)bytesReceived withMessage:(ALMessage *)alMessage {
    [self.messageServiceDelegate updateBytesDownloaded:(NSUInteger)bytesReceived];
}

- (void)onUpdateBytesUploaded:(int64_t)bytesSent withMessage:(ALMessage *)alMessage {
    [self.messageServiceDelegate updateBytesUploaded:(NSInteger)bytesSent];
}

- (void)onUploadCompleted:(ALMessage *)alMessage withOldMessageKey:(NSString *)oldMessageKey {
    [self.messageServiceDelegate uploadCompleted:alMessage];
}

- (void)onUploadFailed:(ALMessage *)alMessage {
    [self.messageServiceDelegate uploadDownloadFailed:alMessage];
}

@end
