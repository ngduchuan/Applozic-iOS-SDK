//
//  ALMessageArrayWrapper.h
//  Applozic
//
//  Created by devashish on 17/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALApplozicSettings.h"
#import "ALMessage.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// `ALMessageArrayWrapper` class is is used for caching the message array data in NSMutableArray used for adding, removing, clearing messages from Array.
@interface ALMessageArrayWrapper : NSObject

/// This will have array of `ALMessage` object.
@property (nonatomic, strong) NSMutableArray *messageArray;

/// :nodoc:
@property (nonatomic, strong) NSString *dateCellText;

/// Used for checking two dates and comparing the current date is older then the new date.
/// @param older Pass the older time stamp.
/// @param newer Pass the newer time stamp.
- (BOOL)checkDateOlder:(NSNumber *)older andNewer:(NSNumber *)newer;

/// Used for fetching the updated Array of messages.
- (NSMutableArray * _Nullable)getUpdatedMessageArray;

/// Used for add array of ALMessage` objects to another Array.
/// @param paramMessageArray An Array of `ALMessage` objects.
- (void)addObjectToMessageArray:(NSMutableArray *)paramMessageArray;

/// Used for adding `ALMessage` object in Array
/// @param message Pass the `ALMessage` object.
- (void)addALMessageToMessageArray:(ALMessage *)message;

/// Used removing a array of `ALMessage` objects from Array.
/// @param paramMessageArray An Array of `ALMessage` objects.
- (void)removeObjectFromMessageArray:(NSMutableArray *)paramMessageArray;

/// Used for removing `ALMessage` object from Array of Messages.
/// @param message Pass the  `ALMessage` object that you want to delete.
- (void)removeALMessageFromMessageArray:(ALMessage *)message;

/// Used for adding lastest message object to array.
/// @param paramMessageArray Pass Array of  `ALMessage` object.
- (void)addLatestObjectToArray:(NSMutableArray *)paramMessageArray;

/// Used for getting date Message.
/// @param messageText Pass date message text.
/// @param message Pass the `ALMessage` object.
- (ALMessage * _Nullable)getDatePrototype:(NSString *)messageText andAlMessageObject:(ALMessage *)message;

/// Used geeting the date for message.
/// @param message Pass the `ALMessage` object.
- (NSString * _Nullable )msgAtTop:(ALMessage *)message;

@end

NS_ASSUME_NONNULL_END
