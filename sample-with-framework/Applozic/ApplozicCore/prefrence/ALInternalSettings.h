//
//  ALInternalSettings.h
//  Applozic
//
//  Created by Sunil on 13/05/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/// `ALInternalSettings` internal class of user defaults storing.
@interface ALInternalSettings : NSObject

+ (void)setRegistrationStatusMessage:(NSString *)message;
+ (NSString *)getRegistrationStatusMessage;

@end
