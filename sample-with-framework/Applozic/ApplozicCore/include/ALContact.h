//
//  ALContact.h
//  ChatApp
//
//  Created by shaik riyaz on 15/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "ALJson.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// For internal use only.
static NSString *const AL_DISPLAY_NAME_UPDATED = @"AL_DISPLAY_NAME_UPDATED";

@interface ALContact : ALJson

@property (nonatomic, retain) NSString *userId;

@property (nonatomic, retain) NSString * _Nullable fullName;

@property (nonatomic, retain) NSString * _Nullable contactNumber;

@property (nonatomic, retain) NSString * _Nullable displayName;

@property (nonatomic, retain) NSString * _Nullable contactImageUrl;

@property (nonatomic, retain) NSString * _Nullable email;

@property(nonatomic, retain) NSString * _Nullable localImageResourceName;

@property (nonatomic, retain) NSString * _Nullable userStatus;

@property(nonatomic, retain) NSString * _Nullable applicationId;

@property (nonatomic) BOOL connected;

@property (nonatomic, retain) NSNumber * _Nullable lastSeenAt;

@property (nonatomic, strong) NSNumber * _Nullable unreadCount;

@property (nonatomic) BOOL block;
@property (nonatomic) BOOL blockBy;
@property (nonatomic, retain) NSNumber * _Nullable userTypeId;
@property (nonatomic, retain) NSNumber * _Nullable contactType;
@property (nonatomic, retain) NSNumber * _Nullable deletedAtTime;
@property (nonatomic, retain) NSMutableDictionary * _Nullable metadata;
@property (nonatomic, retain) NSNumber * _Nullable roleType;
@property (nonatomic, strong) NSNumber * _Nullable notificationAfterTime;
@property (nonatomic, strong) NSNumber * _Nullable status;

- (instancetype)initWithDict:(NSDictionary *)dictionary;
- (void)populateDataFromDictonary:(NSDictionary *)dict;

- (NSString *)getDisplayName;
- (NSMutableDictionary * _Nullable)getMetaDataDictionary:(NSString *)jsonString;

- (BOOL)isNotificationMuted;
- (BOOL)isChatDisabled;
- (BOOL)isDisplayNameUpdateRequired;
- (NSMutableDictionary *)appendMetadataIn:(NSString *)metadataString;
- (BOOL)isDeleted;
@end

NS_ASSUME_NONNULL_END
