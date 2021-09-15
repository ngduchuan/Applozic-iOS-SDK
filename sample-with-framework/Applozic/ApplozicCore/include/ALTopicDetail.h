//
//  ALTopicDetail.h
//  Applozic
//
//  Created by Devashish on 27/02/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALJson.h"
/*
 
 topicDetail = "{\"title\":\"Product on demand\",\"subtitle\":\"PID : 4398343dsjhsjdhsdj9\",\"link\":\"http://www.msupply.com/media/catalog/product/cache/1/image/400x492/9df78eab33525d08d6e5fb8d27136e95/E/L/ELEL10014724_1.jpg\",\"key1\":\"Qty\",\"value1\":\"50\",\"key2\":\"Price\",\"value2\":\"Rs.90\"}";
 topicId = product2;
 },
 
 */

/// `ALTopicDetail` class is used for context based chat this will have topic details.
@interface ALTopicDetail : ALJson

/// Set the title of context based topic chat.
@property (nonatomic, strong) NSString *title;

/// Set the subtitle of the context based topic chat.
@property (nonatomic, strong) NSString *subtitle;

/// Set the pId.
@property (nonatomic, strong) NSString *pId;

/// Set the image URL link.
@property (nonatomic, strong) NSString *link;

/// Set the key1 title.
@property (nonatomic, strong) NSString *key1;

/// Set the value1 description.
@property (nonatomic, strong) NSString *value1;

/// Set the key2 title.
@property (nonatomic, strong) NSString *key2;

/// Set the value2 description.
@property (nonatomic, strong) NSString *value2;

/// Set the Topic id of the product.
@property (nonatomic, strong) NSString *topicId;

/// :nodoc:
@property (nonatomic,strong)  NSMutableArray *fallBackTemplateList;

/// This method is used parsing topic JSON Dictionary.
/// @param detailJson Pass the JSON Dictionary.
- (id)initWithDictonary:(NSDictionary *)detailJson;

/// This method used for parsing the JSON.
/// @param detailJson Pass the JSON Dictionary.
- (void)parseMessage:(id)detailJson;


@end
