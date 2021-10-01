//
//  ALPasswordQueryable.h
//  ApplozicCore
//
//  Created by apple on 11/03/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALSecureStore.h"

NS_ASSUME_NONNULL_BEGIN

/// `ALPasswordQueryable` class is used for password keychain access secure store.
@interface ALPasswordQueryable : NSObject <ALSecureStoreQueryable>

/// Init is not avaliable.
-(nonnull instancetype)init NS_UNAVAILABLE;

/// This method is used for init store service name which is used for identifying the keychain store.
/// @param service Pass the name of the store to access.
-(nonnull instancetype)initWithService:(NSString * _Nonnull)service;

/// This is set from `initWithService` and can be access the name using service string.
@property (nonatomic) NSString *serviceString;

/// This is set from `initWithService` name of the keychain access group.
@property (nonatomic) NSString *appKeychainAcessGroup;

/// This is implemented from `ALSecureStoreQueryable` it is Dictionary for
@property (nonatomic, readonly, copy) NSMutableDictionary<NSString *, id> * _Nonnull query;

@end

NS_ASSUME_NONNULL_END
