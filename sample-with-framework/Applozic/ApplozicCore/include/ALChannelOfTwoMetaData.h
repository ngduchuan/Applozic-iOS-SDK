//
//  ALChannelOfTwoMetaData.h
//  Applozic
//
//  Created by Mihir on 02/05/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALChannelOfTwoMetaData : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString * _Nullable price;
@property (nonatomic, strong) NSString *link;
- (NSMutableDictionary *)toDict:(ALChannelOfTwoMetaData *)metadata;
@end

NS_ASSUME_NONNULL_END
