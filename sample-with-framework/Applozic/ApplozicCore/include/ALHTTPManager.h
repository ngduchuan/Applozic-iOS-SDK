//
//  ALHTTPManager.h
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALDownloadTask.h"
#import "ALMessage.h"
#import "ALUploadTask.h"
#import "ApplozicClient.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALHTTPManager : NSObject <NSURLSessionDataDelegate,NSURLSessionDelegate>

@property (nonatomic, weak) id<ApplozicAttachmentDelegate> _Nullable attachmentProgressDelegate;

@property (nonatomic, weak) id<ApplozicUpdatesDelegate> _Nullable delegate;

@property (nonatomic, strong) NSMutableData * _Nullable buffer;

@property (nonatomic) NSUInteger *length;

@property (nonatomic) ALUploadTask *uploadTask;

@property (nonatomic) ALDownloadTask *downloadTask;

@property (nonatomic, strong) ALResponseHandler *responseHandler;

- (void)processDownloadForMessage:(ALMessage *)message isAttachmentDownload:(BOOL)attachmentDownloadFlag;

- (void)processUploadFileForMessage:(ALMessage *)message uploadURL:(NSString *)uploadURL;

- (void)uploadProfileImage:(UIImage *)profileImage
              withFilePath:(NSString *)filePath
                 uploadURL:(NSString *)uploadURL
            withCompletion:(void(^)(NSData * _Nullable data, NSError * _Nullable error)) completion;

@end

NS_ASSUME_NONNULL_END
