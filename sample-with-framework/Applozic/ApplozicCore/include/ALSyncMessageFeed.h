//
//  ALSyncMessageFeed.h
//  ChatApp
//
//  Created by Devashish on 20/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALJson.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALSyncMessageFeed : ALJson

@property(nonatomic,copy) NSNumber * _Nullable lastSyncTime;

@property(nonatomic,copy) NSString * _Nullable currentSyncTime;

@property(nonatomic) NSMutableArray * _Nullable messagesList;

@property(nonatomic) NSMutableArray * _Nullable deliveredMessageKeys;

@property(nonatomic, assign) BOOL sent;

@property(nonatomic, assign) BOOL isRegisterdIdInvalid;

@end

NS_ASSUME_NONNULL_END
