//
//  ALConnectionQueueHandler.h
//  ChatApp
//
//  Created by shaik riyaz on 26/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ALConnectionQueueHandler : NSObject

@property (nonatomic,retain) NSMutableArray * _Nullable mConnectionsArray;

+ (ALConnectionQueueHandler *)sharedConnectionQueueHandler;

- (NSMutableArray *_Nullable)getCurrentConnectionQueue;

@end
NS_ASSUME_NONNULL_END
