//
//  ALTopicDetail.h
//  Applozic
//
//  Created by Devashish on 27/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALJson.h"
#import <Foundation/Foundation.h>

/*
 
 topicDetail = "{\"title\":\"Product on demand\",\"subtitle\":\"PID : 4398343dsjhsjdhsdj9\",\"link\":\"http://www.msupply.com/media/catalog/product/cache/1/image/400x492/9df78eab33525d08d6e5fb8d27136e95/E/L/ELEL10014724_1.jpg\",\"key1\":\"Qty\",\"value1\":\"50\",\"key2\":\"Price\",\"value2\":\"Rs.90\"}";
 topicId = product2;
 },
 
 */

NS_ASSUME_NONNULL_BEGIN

/// `ALTopicDetail` class is used for context based chat this will have topic details.
@interface ALTopicDetail : ALJson

/// Sets the title of context based topic chat.
@property (nonatomic, strong) NSString * _Nullable title;

/// Sets the subtitle of the context based topic chat.
@property (nonatomic, strong) NSString * _Nullable subtitle;

/// Sets the pId.
@property (nonatomic, strong) NSString * _Nullable pId;

/// Sets the image URL link.
@property (nonatomic, strong) NSString * _Nullable link;

/// Sets the key1 title.
@property (nonatomic, strong) NSString * _Nullable key1;

/// Sets the value1 .
@property (nonatomic, strong) NSString * _Nullable value1;

/// Sets the key2 title.
@property (nonatomic, strong) NSString * _Nullable key2;

/// Sets the value2.
@property (nonatomic, strong) NSString * _Nullable value2;

/// Sets the Topic id of the product.
@property (nonatomic, strong) NSString * _Nullable topicId;

/// :nodoc:
@property (nonatomic,strong)  NSMutableArray * _Nullable fallBackTemplateList;

/// This method is used parsing topic JSON Dictionary.
/// @param detailJson Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)detailJson;

@end

NS_ASSUME_NONNULL_END
