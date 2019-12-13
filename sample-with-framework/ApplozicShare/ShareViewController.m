//
//  ShareViewController.m
//  ApplozicShare
//
//  Created by apple on 25/04/19.
//  Copyright © 2019 applozic Inc. All rights reserved.
//

#import "ShareViewController.h"
#import <Applozic/Applozic.h>
#import <MobileCoreServices/MobileCoreServices.h>


@interface ShareViewController ()
@property (strong, nonatomic) ALMessage *theMessage;

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}


- (void)didSelectPost {

    if([ALUserDefaultsHandler isLoggedIn]){

        [self passSelectedItemsToApp];
    }

}


- ( NSString * ) saveImageToAppGroupFolder: ( UIImage * ) image{

    assert( NULL != image );

    NSURL * urlForDocumentsDirectory =  [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[ALApplozicSettings getShareExtentionGroup]];
    NSString * timestamp = [NSString stringWithFormat:@"IMG-%f.jpeg",[[NSDate date] timeIntervalSince1970] * 1000];
    NSURL * fileURL =  [urlForDocumentsDirectory URLByAppendingPathComponent:timestamp];
    NSData * imageData = [image getCompressedImageData];
    [imageData writeToURL:fileURL atomically:YES];

    return fileURL.path;
}



- ( void ) passSelectedItemsToApp
{
    NSExtensionItem * item = self.extensionContext.inputItems.firstObject;

    // Reset the counter and the argument list for invoking the app:

    // Iterate through the attached files
    for ( NSItemProvider * itemProvider in item.attachments )
    {
        
        // Check if we are sharing a Image
        if ( [ itemProvider hasItemConformingToTypeIdentifier: ( NSString * ) kUTTypeImage ] )
        {
            // Load it, so we can get the path to it
            [ itemProvider loadItemForTypeIdentifier: ( NSString * ) kUTTypeImage
                                             options: NULL
                                   completionHandler: ^ ( UIImage * image, NSError * error )
             {

                 if ( NULL != error )
                 {
                     NSLog( @"There was an error retrieving the attachments: %@", error );
                     return;
                 }

                 // The app won't be able to access the images by path directly in the Camera Roll folder,
                 // so we temporary copy them to a folder which both the extension and the app can access:
                 NSString * filePath = [ self saveImageToAppGroupFolder: image];
                 [self buildAttachmentMessageWithFilePath:filePath withMessageText:self.textView.text];
             } ];
        }
    }
}


-(void)buildAttachmentMessageWithFilePath:(NSString *)filePath withMessageText:(NSString*) messageText{

    ALFileMetaInfo *info = [ALFileMetaInfo new];

    info.blobKey = nil;
    info.contentType = @"";
    info.createdAtTime = nil;
    info.key = nil;
    info.name = @"";
    info.size = @"";
    info.userKey = @"";
    info.thumbnailUrl = @"";
    info.progressValue = 0;
    self.theMessage = [ALMessage alloc];
    self.theMessage.type = @"5";
    self.theMessage.message = messageText;
    self.theMessage.fileMeta = info;
    self.theMessage.imageFilePath = [filePath lastPathComponent];
    self.theMessage.createdAtTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000];
     self.theMessage.deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    self.theMessage.sendToDevice = NO;
    self.theMessage.shared = NO;
    self.theMessage.fileMeta = info;
    self.theMessage.storeOnDevice = NO;
    self.theMessage.key = [[NSUUID UUID] UUIDString];
    self.theMessage.delivered = NO;
    self.theMessage.fileMetaKey = nil;
    self.theMessage.source = AL_SOURCE_IOS;
    [self launchContactScreen:self.theMessage];
}


-(void)launchContactScreen:(ALMessage *)message{
    ALChatLauncher* chatmanager = [[ALChatLauncher alloc] init];
    [chatmanager launchContactScreenWithMessage:message andFromViewController:self];

}


- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}


- (void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissViewController:)
                                                 name:@"DISMISS_SHARE_EXTENSION"
                                               object:nil];
}

-(void)dismissViewController:(NSNotification *)notifyObject{
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}


@end
