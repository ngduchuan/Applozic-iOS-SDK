//
//  ALApplicationInfo.m
//  Applozic
//
//  Created by Mukesh Thawani on 05/06/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import "ALApplicationInfo.h"
#import "ALUtilityClass.h"
#import "ALUserDefaultsHandler.h"
#import "ALConstant.h"

@implementation ALApplicationInfo


-(BOOL)isChatSuspended
{
    BOOL debugflag = [ALUtilityClass isThisDebugBuild];

    if(debugflag)
    {
        return NO;
    }
    if([ALUserDefaultsHandler getUserPricingPackage] == ALCLOSED
       || [ALUserDefaultsHandler getUserPricingPackage] == ALBETA
       || [ALUserDefaultsHandler getUserPricingPackage] == ALSUSPENDED)
    {
        return YES;
    }
    return NO;
}

-(BOOL)showPoweredByMessage
{
    BOOL debugflag = [ALUtilityClass isThisDebugBuild];
    if(debugflag) {
        return NO;
    }
    if([ALUserDefaultsHandler getUserPricingPackage] == ALSTARTER) {
        return YES;
    }
    return NO;
}

@end
