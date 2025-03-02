//
//  NSString+Encode.h
//  Applozic
//
//  Created by Divjyot Singh on 21/04/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Extension class of String
@interface NSString (Encode)

/// Returns the encoded URL string in UTF8 format
- (NSString *)urlEncodeUsingNSUTF8StringEncoding; // Direct UTF8 encoding
@end
