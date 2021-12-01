//
//  ALUserDefaultsUtility.h
//  ApplozicCore
//
//  Created by Sunil on 01/12/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALUserDefaultsUtility : NSObject

+ (NSData * _Nullable)archivedDataWithRootObject:(id)rootObject;

+ (UIColor * _Nullable)unarchiveObjectWithData:(NSData * _Nullable)data;

@end

NS_ASSUME_NONNULL_END
