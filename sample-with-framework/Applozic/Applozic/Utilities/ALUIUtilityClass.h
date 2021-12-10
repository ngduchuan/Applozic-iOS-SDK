//
//  ALUIUtilityClass.h
//  Applozic
//
//  Created by apple on 17/02/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplozicCore/ApplozicCore.h>

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && (MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 568.0) && ((IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale) || !IS_OS_8_OR_LATER))
#define IS_STANDARD_IPHONE_6 (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 667.0  && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale)
#define IS_ZOOMED_IPHONE_6 (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 568.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale > [UIScreen mainScreen].scale)
#define IS_STANDARD_IPHONE_6_PLUS (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 736.0)
#define IS_ZOOMED_IPHONE_6_PLUS (IS_IPHONE && MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width) == 375.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale < [UIScreen mainScreen].scale)
#define IS_IPHONE_6 (IS_STANDARD_IPHONE_6 || IS_ZOOMED_IPHONE_6)
#define IS_IPHONE_6_PLUS (IS_STANDARD_IPHONE_6_PLUS || IS_ZOOMED_IPHONE_6_PLUS)
#define IS_OS_9_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

static NSString *const APPLOZIC_CHAT_BACKGROUND_COLOR = @"ApplozicChatBackgroundColor";

@interface ALUIUtilityClass : NSObject

+ (UIImage *)getImageFromFramworkBundle:(NSString *) UIImageName;
+ (UIImage *)getVOIPMessageImage:(ALMessage *)alMessage;
+ (void) downloadImageUrlAndSet: (NSString *)blobKey
                      imageView:(UIImageView *)imageView
                   defaultImage:(NSString *)defaultImage;


+ (UIAlertController *)displayLoadingAlertControllerWithText:(NSString *)loadingText;

+ (void)dismissAlertController:(UIAlertController *)alertController
                withCompletion:(void (^)(BOOL dismissed)) completion;
+ (void)movementAnimation:(UIButton *)button andHide:(BOOL)flag;

+ (void)displayToastWithMessage:(NSString *)toastMessage;

+ (UIView *)setStatusBarStyle;

+ (UIImage *)getNormalizedImage:(UIImage *)rawImage;

+ (id)parsedALChatCostomizationPlistForKey:(NSString *)key;

+ (void)showAlertMessage:(NSString *)text andTitle:(NSString *)title;

+ (UIImage *)getImageFromFilePath:(NSString *)filePath;

+ (UIColor*)colorWithHexString:(NSString*)hex;

+ (UIImage *)generateVideoThumbnailImage:(NSString *)videoFilePATH;

+ (UIImage *)generateImageThumbnailForVideoWithURL:(NSURL *)url;

+ (void)imageGeneratorForVideoWithURL:(NSURL *)url withCompletion:(void (^)(UIImage *image)) completion;

+ (void)permissionPopUpWithMessage:(NSString *)msgText andViewController:(UIViewController *)viewController;
+ (void)setAlertControllerFrame:(UIAlertController *)alertController andViewController:(UIViewController *)viewController;
+ (NSString *)getNameAlphabets:(NSString *)actualName;

+ (void)openApplicationSettings;

@end
