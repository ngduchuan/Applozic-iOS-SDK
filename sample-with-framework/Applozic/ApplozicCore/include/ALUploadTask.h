//
//  ALUploadTask.h
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALMessage.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALUploadTask` is used for uploading the attachment file.
@interface ALUploadTask : NSObject

/// Sets the file name of the attachment.
@property (nonatomic, copy) NSString *filePath;

/// Name of the file.
@property (nonatomic, copy) NSString *fileName;

/// Sets the key from `ALMessage` object.
@property (nonatomic, copy) NSString *identifier;

/// Sets the the `ALMessage` object.
@property (nonatomic, strong) ALMessage *message;

/// Sets the video Thumbnail name.
@property (nonatomic, strong) NSString *videoThumbnailName;

@end

NS_ASSUME_NONNULL_END
