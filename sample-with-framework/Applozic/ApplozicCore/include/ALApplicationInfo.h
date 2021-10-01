//
//  ALApplicationInfo.h
//  Applozic
//
//  Created by Mukesh Thawani on 05/06/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/// `ALApplicationInfo` class is used for checking the status of account like chat is Suspended, Show the powerd by message.
/// @warning `ALApplicationInfo` class used only for internal.
@interface ALApplicationInfo : NSObject

/// Used for checking if the chat is suspended or not.
///
/// Returns `YES` in case of chat is suspended or closed or using Beta APP-ID in release mode and In debug mode it will return `NO`.
- (BOOL)isChatSuspended;

/// Returns `YES` in  case of starter Plan and in Debug mode it will return `NO`.
- (BOOL)showPoweredByMessage;

@end
