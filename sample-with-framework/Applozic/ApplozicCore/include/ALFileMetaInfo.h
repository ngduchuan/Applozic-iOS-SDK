//
//  ALFileMetaInfo.h
//  ChatApp
//
//  Created by shaik riyaz on 23/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ALJson.h"

/// `ALFileMetaInfo` class is used for attachment object.
@interface ALFileMetaInfo : ALJson

/// File attachment key.
@property (nonatomic,copy) NSString *key;

/// User key of the user who set the attachment file.
@property (nonatomic,copy) NSString *userKey;

/// Blob key of the file attachment.
@property (nonatomic,copy) NSString *blobKey;

/// Thumbnail blob key in case of image, video.
@property (nonatomic,copy) NSString *thumbnailBlobKey;

/// Local thumbnail file name.
@property (nonatomic,copy) NSString *thumbnailFilePath;

/// Name of the file attachment.
@property (nonatomic,copy) NSString *name;

/// Attachment url.
@property (nonatomic,copy) NSString *url;

/// Size of the file.
@property (nonatomic,copy) NSString *size;

/// Content type of attachment file.
@property (nonatomic,copy) NSString *contentType;

/// Thumbnail url
@property (nonatomic,copy) NSString *thumbnailUrl;

/// Time of the attachment created at.
@property (nonatomic,copy) NSNumber *createdAtTime;

/// :nodoc:
@property (nonatomic, assign) CGFloat progressValue;

/// Returns a size of the file.
- (NSString *)getTheSize;

/// Populate the JSON of the file metadata.
/// @param dict Dictionary of file meta json.
- (ALFileMetaInfo *)populate:(NSDictionary *)dict;

@end
