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

/// <#Description#>
@property (nonatomic,copy) NSString *key;

/// <#Description#>
@property (nonatomic,copy) NSString *userKey;

/// <#Description#>
@property (nonatomic,copy) NSString *blobKey;

/// <#Description#>
@property (nonatomic,copy) NSString *thumbnailBlobKey;

/// <#Description#>
@property (nonatomic,copy) NSString *thumbnailFilePath;

/// <#Description#>
@property (nonatomic,copy) NSString *name;

/// <#Description#>
@property (nonatomic,copy) NSString *url;

/// <#Description#>
@property (nonatomic,copy) NSString *size;

/// <#Description#>
@property (nonatomic,copy) NSString *contentType;

/// <#Description#>
@property (nonatomic,copy) NSString *thumbnailUrl;

/// <#Description#>
@property (nonatomic,copy) NSNumber *createdAtTime;


/// <#Description#>
@property (nonatomic, assign) CGFloat progressValue;


/// <#Description#>
- (NSString *)getTheSize;

/// <#Description#>
/// @param dict <#dict description#>
- (ALFileMetaInfo *)populate:(NSDictionary *)dict;

@end
