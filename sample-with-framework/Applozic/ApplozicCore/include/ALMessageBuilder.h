//
//  ALMessageBuilder.h
//  Applozic
//
//  Created by apple on 04/07/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

/// `ALMessageBuilder` is object builder for sending a text or attachment message to server.
///
/// For sending message in one to one chat:
/// @code
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
///    alMessageBuilder.to = @"<USER-ID>"; //Pass userId to whom you want to send a message.
///    alMessageBuilder.message = @"<MESSAGE-TEXT>"; // Pass message text here.
/// }];
/// @endcode
/// For sending a message in channel or group chat:
/// @code
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
///     alMessageBuilder.groupId = @<CHANNEL-KEY>; //Pass channelKey here to whom you want to send a message.
///     alMessageBuilder.message = @"<MESSAGE-TEXT>"; // Pass message text here.
/// }];
/// @endcode
/// For sending an attachment message:
/// @code
/// ALMessage *alMessage = [ALMessage build:^(ALMessageBuilder * alMessageBuilder) {
///   alMessageBuilder.to = @"<USER-ID>"; // Set the userId of the receiver to send message in one to one chat and will be nil case of channel or group chat.
///   alMessageBuilder.groupId = @<CHANNEL-KEY>; // Pass channelKey to channel/group you want to send a attchment message else will be nil.
///   alMessageBuilder.imageFilePath = @"Pass the name of the file"; // File name
///   alMessageBuilder.contentType = ALMESSAGE_CONTENT_ATTACHMENT;
/// }];
/// @endcode
@interface ALMessageBuilder : NSObject

/// Set the userId of the receiver to send message in one to one chat.
/// @warning This has to be nil in case of channel or group message make sure to not set in channel or group messaging.
@property (nonatomic, copy) NSString *to;

/// Set the message text.
@property (nonatomic, copy) NSString *message;

/// Set the content type of message list of content types can be found in `ALMessage` class static constants.
@property(nonatomic) short contentType;

/// Set the channelKey or groupId to send a message to channel or group otherwise it will be nil.
/// @warning This has to be nil in case of one to one message make sure to not set in one to one messaging.
@property (nonatomic, copy) NSNumber *groupId;

/// :nodoc:
@property(nonatomic,copy) NSNumber *conversationId;

/// Set the extra information as meta data which will be in key value Dictionary in each message that can be sent.
@property (nonatomic,retain) NSMutableDictionary *metadata;

/// Set the name of the file that you want to upload in chat.
/// @note Make sure that the file is exist in document directory if the file not exits make sure to save it and set.
@property (nonatomic, copy) NSString *imageFilePath;

@end
