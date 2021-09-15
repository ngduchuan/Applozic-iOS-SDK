//
//  UIImage+Utility.h
//  ChatApp
//
//  Created by shaik riyaz on 22/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import <UIKit/UIKit.h>

/// `UIImage` utility class for  image.
@interface UIImage (Utility)

/// Use this method for geeting size from UIImage.
- (double)getImageSizeInMb;
/// Use this method for geeting compressed image.
/// @param sizeInMb Pass the size of image.
- (UIImage *)getCompressedImageLessThanSize:(double)sizeInMb;
/// Use this method compressed data.
- (NSData *)getCompressedImageData;

@end
