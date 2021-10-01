//
//  ALSearchResultCache.h
//  Applozic
//
//  Created by Shivam Pokhriyal on 02/07/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALChannel.h"
#import "ALContact.h"
#import "ALUserDetail.h"

/// `ALSearchResultCache` class is used for storing the `ALChannel` and `ALUserDetail` object.
@interface ALSearchResultCache : NSObject

/// Instance method of `ALSearchResultCache`.
+ (ALSearchResultCache *)shared;

/// This method is used for storing the array of `ALChannel` objects.
/// @param channels Pass the array of `ALChannel` objects.
- (void)saveChannels:(NSMutableArray<ALChannel *> *)channels;

/// This method is used for storing the array of `ALUserDetail` objects.
/// @param userDetails Pass the array of `ALUserDetail` objects.
- (void)saveUserDetails:(NSMutableArray<ALUserDetail *> *)userDetails;

/// This method is used for fetching the `ALChannel` object from `ALSearchResultCache`.
/// @param key Pass the channelKey or groupId.
- (ALChannel *)getChannelWithId:(NSNumber *)key;

/// This method is used for fetching the `ALContact` object from `ALSearchResultCache`.
/// @param key Pass the userId to fetch the contact.
- (ALContact *)getContactWithId:(NSString *)key;

@end
