//
//  ALUIUtilityClass.m
//  Applozic
//
//  Created by Sunil on 17/02/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import "ALUIUtilityClass.h"

@implementation ALUIUtilityClass

+(UIImage *)getImageFromFramworkBundle:(NSString *) UIImageName{

    NSBundle * bundle = [NSBundle bundleForClass:ALUIUtilityClass.class];
    UIImage *image = [UIImage imageNamed:UIImageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

+(UIImage *)getVOIPMessageImage:(ALMessage *)alMessage
{
    NSString *msgType = (NSString *)[alMessage.metadata objectForKey:@"MSG_TYPE"];
    BOOL flag = [[alMessage.metadata objectForKey:@"CALL_AUDIO_ONLY"] boolValue];

    NSString * imageName = @"";

    if([msgType isEqualToString:@"CALL_MISSED"] || [msgType isEqualToString:@"CALL_REJECTED"])
    {
        imageName = @"missed_call.png";
    }
    else if([msgType isEqualToString:@"CALL_END"])
    {
        imageName = flag ? @"audio_call.png" : @"ic_action_video.png";
    }

    UIImage *image = [self getImageFromFramworkBundle:imageName];

    return image;
}

+(void) downloadImageUrlAndSet: (NSString *) blobKey
                     imageView:(UIImageView *) imageView
                  defaultImage:(NSString *) defaultImage {

    if (blobKey) {
        NSURL * theUrl1 = [NSURL URLWithString:blobKey];
        [imageView sd_setImageWithURL:theUrl1 placeholderImage:[ALUIUtilityClass getImageFromFramworkBundle:defaultImage] options:SDWebImageRefreshCached];
    }

}


@end
