//
//  ALSyncMessageFeed.h
//  ChatApp
//
//  Created by Devashish on 20/09/15.
//  Copyright © 2015 AppLogic. All rights reserved.
//

#import "ALJson.h"
#import <Foundation/Foundation.h>

@interface ALSyncMessageFeed : ALJson

@property(nonatomic,copy) NSNumber *lastSyncTime;

@property(nonatomic,copy) NSString *currentSyncTime;

@property(nonatomic) NSMutableArray *messagesList;

@property(nonatomic) NSMutableArray *deliveredMessageKeys;

@property(nonatomic, assign) BOOL sent;

@property(nonatomic, assign) BOOL isRegisterdIdInvalid;

@end
