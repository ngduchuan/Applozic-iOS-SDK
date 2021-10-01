//
//  ALMessageArrayWrapper.h
//  Applozic
//
//  Created by devashish on 17/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMessage.h"
#import "ALApplozicSettings.h"

/// `ALMessageArrayWrapper` class is is used for caching the message array data in NSMutableArray used for adding, removing, clearing messages from Array.
@interface ALMessageArrayWrapper : NSObject

/// This will have array of `ALMessage` object.
@property (nonatomic, strong) NSMutableArray *messageArray;

/// :nodoc:
@property (nonatomic, strong) NSString *dateCellText;

/// This method is used for checking two dates and comparing the current date is older then the new date.
/// @param older Pass the older time stamp.
/// @param newer Pass the newer time stamp.
- (BOOL)checkDateOlder:(NSNumber *)older andNewer:(NSNumber *)newer;

/// This method is used for fetching the updated Array of messages.
- (NSMutableArray *)getUpdatedMessageArray;

/// This method is used for add array of ALMessage` objects to another Array.
/// @param paramMessageArray An Array of `ALMessage` objects.
- (void)addObjectToMessageArray:(NSMutableArray *)paramMessageArray;

/// This method is used for adding `ALMessage` object in Array
/// @param alMessage Pass the `ALMessage` object.
- (void)addALMessageToMessageArray:(ALMessage *)alMessage;

/// This method is used removing a array of `ALMessage` objects from Array.
/// @param paramMessageArray An Array of `ALMessage` objects.
- (void)removeObjectFromMessageArray:(NSMutableArray *)paramMessageArray;

/// This method is used for removing `ALMessage` object from Array of Messages.
/// @param alMessage Pass the  `ALMessage` object that you want to delete.
- (void)removeALMessageFromMessageArray:(ALMessage *)alMessage;

/// This method is used for adding lastest message object to array.
/// @param paramMessageArray Pass Array of  `ALMessage` object.
- (void)addLatestObjectToArray:(NSMutableArray *)paramMessageArray;

/// This method is used for getting date Message.
/// @param messageText Pass date message text.
/// @param almessage Pass the `ALMessage` object.
- (ALMessage *)getDatePrototype:(NSString *)messageText andAlMessageObject:(ALMessage *)almessage;

/// This method is used geeting the date for message.
/// @param almessage Pass the `ALMessage` object.
- (NSString *)msgAtTop:(ALMessage *)almessage;

@end
