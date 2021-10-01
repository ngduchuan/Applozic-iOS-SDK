//
//  UIImage+Utility.h
//  ChatApp
//
//  Created by shaik riyaz on 22/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import <UIKit/UIKit.h>

/// `UIImage` extension utility class for image.
@interface UIImage (Utility)

/// Use the method for getting size from UIImage.
- (double)getImageSizeInMb;
/// Use the method for geeting compressed image.
/// @param sizeInMb Pass the size of image.
- (UIImage *)getCompressedImageLessThanSize:(double)sizeInMb;
/// Use the method compressed data.
- (NSData *)getCompressedImageData;

@end
