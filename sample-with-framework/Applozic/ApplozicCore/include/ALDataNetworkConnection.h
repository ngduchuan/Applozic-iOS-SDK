//
//  ALDataNetworkConnection.h
//  Applozic
//
//  Created by devashish on 02/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALDataNetworkConnection : UIViewController

+ (BOOL)checkDataNetworkAvailable;
+ (BOOL)noInternetConnectionNotification;

@end

NS_ASSUME_NONNULL_END
