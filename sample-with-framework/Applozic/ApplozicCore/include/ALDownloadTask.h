//
//  ALDownloadTask.h
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ALMessage.h"
#import <Foundation/Foundation.h>

/// `ALDownloadTask` is class used for creating an download task.
@interface ALDownloadTask : NSObject

/// Sets the YES or true in case of Thumbnail.
@property (nonatomic) BOOL isThumbnail;

/// Sets the name of the file.
@property (nonatomic, copy) NSString *fileName;

/// Sets the `ALMessage` object.
@property (nonatomic, strong) ALMessage *message;

@end
