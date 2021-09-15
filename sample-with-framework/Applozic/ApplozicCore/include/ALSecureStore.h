//
//  ALSecureStore.h
//  ApplozicCore
//
//  Created by apple on 11/03/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// `ALSecureStoreQueryable` protocol is used in `ALSecureStore`.
@protocol ALSecureStoreQueryable <NSObject>

/// This is used for query the secure store.
@property (nonatomic, readonly, copy) NSMutableDictionary<NSString *, id> * _Nonnull query;
@end

/// `ALSecureStore` is used for storing the data in key chains secure store.
@interface ALSecureStore : NSObject

/// `ALSecureStoreQueryable`protocol intance.
@property (nonatomic) id <ALSecureStoreQueryable> secureStoreQueryable;

/// init is not avaliable for accessing.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// This method is used for init the Generic Password secure store protocol.
/// @param secureStoreQueryable Pass the class of the type `ALSecureStoreQueryable` protocol.
- (nonnull instancetype)initWithSecureStoreQueryable:(id <ALSecureStoreQueryable> _Nonnull)secureStoreQueryable;

/// This method is used for set the data in secure store.
/// @param value Pass the value to store.
/// @param userAccount Pass the key of the user account name.
/// @param error Will have error if there is failed to remove the data from store.
- (BOOL)setValue:(NSString * _Nonnull)value
  forUserAccount:(NSString * _Nonnull)userAccount
           error:(NSError * _Nullable * _Nullable)error;

/// This method is used for getting a value from secure store.
/// @param userAccount Pass the key of the user account.
/// @param error Will have error if there is failed to remove the data from store.
- (NSString * _Nullable)getValueFor:(NSString * _Nonnull)userAccount
                              error:(NSError * _Nullable * _Nullable)error;

/// This method is used for removing the single data from secure store.
/// @param userAccount Pass the key of user account.
/// @param error Will have error if there is failed to remove the data from store.
- (BOOL)removeValueFor:(NSString * _Nonnull)userAccount
                 error:(NSError * _Nullable * _Nullable)error;

/// This method will remove all the data from key chains for the Applozic secure store.
/// @param error Will have error if there is failed to remove all the data from store.
- (BOOL)removeAllValuesAndReturnError:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
