//
//  ALErrorResponse.h
//  ApplozicCore
//
//  Created by Sunil on 17/11/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALErrorResponse : NSObject

@property (retain ,nonatomic) NSString * _Nullable errorCode;

@property (retain ,nonatomic) NSString * _Nullable errorDescription;

@property (retain ,nonatomic) NSString * _Nullable displayMessage;

- (id)initWithDictionary:(NSDictionary *)responseDictionary;

-(NSString * _Nullable)errorDescriptionMessage;

@end

NS_ASSUME_NONNULL_END
