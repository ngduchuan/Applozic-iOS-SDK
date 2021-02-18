//
//  ALUIUtilityClass.h
//  Applozic
//
//  Created by apple on 17/02/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplozicCore/ApplozicCore.h>
#import "UIImageView+WebCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALUIUtilityClass : NSObject

+(UIImage *)getImageFromFramworkBundle:(NSString *) UIImageName;
+(UIImage *)getVOIPMessageImage:(ALMessage *)alMessage;
+(void) downloadImageUrlAndSet: (NSString *) blobKey
                     imageView:(UIImageView *) imageView
                  defaultImage:(NSString *) defaultImage;
@end

NS_ASSUME_NONNULL_END
