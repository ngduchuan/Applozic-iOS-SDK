//
//  ALDownloadTask.h
//  Applozic
//
//  Created by apple on 25/03/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessage.h"

/// `ALDownloadTask` is class used for creating an download task.
@interface ALDownloadTask : NSObject

/// Set the YES or true in case of Thumbnail.
@property (nonatomic) BOOL isThumbnail;

/// Set the name of the file.
@property (nonatomic, copy) NSString *fileName;

/// Set the `ALMessage` object.
@property (nonatomic, strong) ALMessage *message;

@end
