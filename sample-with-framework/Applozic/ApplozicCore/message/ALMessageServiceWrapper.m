//
//  ALMessageWrapper.m
//  Applozic
//
//  Created by Adarsh Kumar Mishra on 12/14/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALApplozicSettings.h"
#import "ALConnectionQueueHandler.h"
#import "ALDownloadTask.h"
#import "ALHTTPManager.h"
#import "ALLogger.h"
#import "ALMessageClientService.h"
#import "ALMessageDBService.h"
#import "ALMessageService.h"
#import "ALMessageServiceWrapper.h"
#import "ALUtilityClass.h"
#import <MobileCoreServices/MobileCoreServices.h>
#include <tgmath.h>

@interface ALMessageServiceWrapper  ()<ApplozicAttachmentDelegate>

@end

@implementation ALMessageServiceWrapper

- (void)sendTextMessage:(NSString *)text andtoContact:(NSString *)toContactId {
    
    ALMessage *message = [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_DEFAULT toSendTo:toContactId withText:text];
    
    [[ALMessageService sharedInstance] sendMessages:message withCompletion:^(NSString *message, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"REACH_SEND_ERROR : %@",error);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:message];
    }];
}


- (void)sendTextMessage:(NSString *)messageText andtoContact:(NSString *)contactId orGroupId:(NSNumber *)channelKey {
    
    ALMessage *message = [self createMessageEntityOfContentType:ALMESSAGE_CONTENT_DEFAULT toSendTo:contactId withText:messageText];
    
    message.groupId = channelKey;
    
    [[ALMessageService sharedInstance] sendMessages:message withCompletion:^(NSString *message, NSError *error) {
        
        if (error) {
            ALSLog(ALLoggerSeverityError, @"REACH_SEND_ERROR : %@",error);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_MESSAGE_SEND_STATUS" object:message];
    }];
}

- (void)sendMessage:(ALMessage *)alMessage
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
    ALMessageDBService *messageDBService = [[ALMessageDBService alloc] init];
    DB_Message *dbMessageEntity = [messageDBService createMessageEntityForDBInsertionWithMessage:message];
    message.msgDBObjectId = [dbMessageEntity objectID];
    dbMessageEntity.inProgress = [NSNumber numberWithBool:YES];
    dbMessageEntity.isUploadFailed = [NSNumber numberWithBool:NO];
    NSError *error =  [[ALDBHandler sharedInstance] saveContext];

    if (self.messageServiceDelegate && error) {
        dbMessageEntity.inProgress = [NSNumber numberWithBool:NO];
        dbMessageEntity.isUploadFailed = [NSNumber numberWithBool:YES];
        [self.messageServiceDelegate uploadDownloadFailed:alMessage];
        return;
    }

    NSDictionary *messageDictionary = [alMessage dictionary];
    
    ALMessageClientService *clientService  = [[ALMessageClientService alloc] init];
    [clientService sendPhotoForUserInfo:messageDictionary withCompletion:^(NSString *message, NSError *error) {
        
        if (error) {
            [self.messageServiceDelegate uploadDownloadFailed:alMessage];
            return;
        }
        ALHTTPManager *httpManager = [[ALHTTPManager alloc] init];
        httpManager.attachmentProgressDelegate = self;
        [httpManager processUploadFileForMessage:[messageDBService createMessageEntity:dbMessageEntity] uploadURL:message];
    }];
    
}


- (ALFileMetaInfo *)getFileMetaInfo {
    ALFileMetaInfo *fileMetaInfo = [ALFileMetaInfo new];
    
    fileMetaInfo.blobKey = nil;
    fileMetaInfo.contentType = @"";
    fileMetaInfo.createdAtTime = nil;
    fileMetaInfo.key = nil;
    fileMetaInfo.name = @"";
    fileMetaInfo.size = @"";
    fileMetaInfo.userKey = @"";
    fileMetaInfo.thumbnailUrl = @"";
    fileMetaInfo.progressValue = 0;
    
    return fileMetaInfo;
}

- (ALMessage *)createMessageEntityOfContentType:(int)contentType
                                       toSendTo:(NSString *)to
                                       withText:(NSString *)text {
    
    ALMessage *message = [ALMessage new];
    
    message.contactIds = to;//1
    message.to = to;//2
    message.message = text;//3
    message.contentType = contentType;//4
    
    message.type = @"5";
    message.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
    message.deviceKey = [ALUserDefaultsHandler getDeviceKeyString ];
    message.sendToDevice = NO;
    message.shared = NO;
    message.fileMeta = nil;
    message.storeOnDevice = NO;
    message.key = [[NSUUID UUID] UUIDString];
    message.delivered = NO;
    message.fileMetaKey = nil;
    
    return message;
}


- (void)downloadMessageAttachment:(ALMessage *)alMessage {

    ALHTTPManager *manager = [[ALHTTPManager alloc] init];
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
