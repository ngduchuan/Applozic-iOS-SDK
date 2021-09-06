//
//  ALUploadTask.h
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessage.h"

/// `ALUploadTask` is used for uploading the attachment file.
@interface ALUploadTask : NSObject

/// Set the file name of the attachment.
@property (nonatomic, copy) NSString *filePath;

/// Name of the file.
@property (nonatomic, copy) NSString *fileName;

/// Set the key from `ALMessage` object.
@property (nonatomic, copy) NSString *identifier;

/// Set the the `ALMessage` object.
@property (nonatomic, strong) ALMessage *message;

/// Set the video Thumbnail name.
@property (nonatomic, strong) NSString *videoThumbnailName;

@end
