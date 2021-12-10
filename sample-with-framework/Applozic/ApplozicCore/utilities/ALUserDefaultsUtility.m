//
//  ALUserDefaultsUtility.m
//  ApplozicCore
//
//  Created by Sunil on 01/12/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import "ALUserDefaultsUtility.h"

@implementation ALUserDefaultsUtility

+ (NSData * _Nullable)archivedDataWithRootObject:(id)rootObject {

    if (!rootObject) {
        return nil;
    }

    NSData *data = nil;
    if (@available(iOS 11, *)) {
        NSError *error;
        data = [NSKeyedArchiver archivedDataWithRootObject:rootObject requiringSecureCoding:NO error:&error];
        if (error) {
            NSLog(@"NSKeyedArchiver archive failed with error: %@", error);
        }
    } else {
        @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            data = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
#pragma clang diagnostic pop
        } @catch (NSException *exception) {
            NSLog(@"NSKeyedArchiver archive failed with exception: %@", exception);
        }
    }
    return data;
}

+ (UIColor * _Nullable)unarchiveObjectWithData:(NSData * _Nullable)data {
    if (!data) {
        return nil;
    }
    UIColor *color = nil;
    if (@available(iOS 11, *)) {
        NSError *error;
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
        unarchiver.requiresSecureCoding = NO;
        color = [unarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:&error];
        if (error) {
            NSLog(@"NSKeyedUnarchiver unarchiver failed with error: %@", error);
        }
    } else {
        @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            color = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
        } @catch (NSException *exception) {
            NSLog(@"NSKeyedUnarchiver unarchiver failed with exception: %@", exception);
        }
    }
    return color;
}


@end
