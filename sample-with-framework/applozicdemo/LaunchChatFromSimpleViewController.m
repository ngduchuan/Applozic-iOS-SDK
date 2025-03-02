//
//  LaunchChatFromSimpleViewController.m
//  applozicdemo
//
//  Created by Devashish on 13/11/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "LaunchChatFromSimpleViewController.h"
#import  <Applozic/ALChatViewController.h>
#import "ALChatManager.h"
#import "ApplozicLoginViewController.h"
#import <Applozic/ALImagePickerHandler.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Applozic/Applozic-Swift.h>
#import <ApplozicCore/ApplozicCore.h>
#import <Applozic/ALUIUtilityClass.h>

@interface LaunchChatFromSimpleViewController ()<MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *sendLogsButton;

- (IBAction)mLaunchChatList:(id)sender;
- (IBAction)mChatLaunchButton:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *notificationSwitch;

@property (strong, nonatomic) IBOutlet UILabel *unreadCountLabel;

@end

@implementation LaunchChatFromSimpleViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //    [self mLaunchChatList:self];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.center = self.view.center;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSUserDefaults * userDefaults = [[NSUserDefaults alloc] init];
    if([userDefaults boolForKey:@"sendLogs"] == YES) {
        self.sendLogsButton.hidden = NO;
    } else {
        self.sendLogsButton.hidden = YES;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdate:) name:@"userUpdate" object:nil];
    
    //////////////////////////   SET AUTHENTICATION-TYPE-ID FOR INTERNAL USAGE ONLY ////////////////////////
    //    [ALUserDefaultsHandler setUserAuthenticationTypeId:(short)APPLOZIC];
    ////////////////////////// ////////////////////////// ////////////////////////// ///////////////////////
    
    [self.unreadCountLabel setBackgroundColor:[UIColor grayColor]];
    [self.unreadCountLabel setTextColor:[UIColor whiteColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMessageHandler) name:NEW_MESSAGE_NOTIFICATION  object:nil];
    [self newMessageHandler];
    if([ALUserDefaultsHandler isLoggedIn]){
        [self insertInitialContacts];
    }
}

//ADD THIS METHOD :

-(void)newMessageHandler
{
    ALContactService * contactService = [ALContactService new];
    NSNumber * count = [contactService getOverallUnreadCountForContact];
    NSLog(@"ICON_COUNT :: %@",count); // UPDATE YOUR VIEW
    [self.unreadCountLabel setText:[NSString stringWithFormat:@"UNREAD COUNT #%@",count]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//===============================================================================
// TO LAUNCH MESSAGE LIST
//
//===============================================================================

- (IBAction)mLaunchChatList:(id)sender {
    
    if (![ALDataNetworkConnection checkDataNetworkAvailable])
    {
        [self.activityView removeFromSuperview];
    }
    else
    {
        [self.activityView startAnimating];
    }

    [self.view addSubview:_activityView];
    ALUser *user = [[ALUser alloc] init];
    [user setUserId:[ALUserDefaultsHandler getUserId]];
    [user setEmail:[ALUserDefaultsHandler getEmailId]];

    ALChatManager * chatManager = [[ALChatManager alloc] init];
    [chatManager connectUserAndLaunchChat:user andFromController:self forUser:nil withGroupId:nil];

    //Adding sample contacts...
    [self insertInitialContacts];
}
- (IBAction)sendLogsAction:(id)sender {
    if ([MFMailComposeViewController canSendMail])
    {

        [ALLogger saveLogArray];
        NSDictionary *infoDictionary = [[NSBundle bundleForClass: [ALLogger class]] infoDictionary];
        NSString *applozicVersion = [infoDictionary valueForKey:@"CFBundleShortVersionString"];

        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        
        [mailer setSubject:@"Applozic Logs File"];
        NSArray *toRecipients = [NSArray arrayWithObjects:@"support@applozic.com", nil];
        [mailer setToRecipients:toRecipients];

        NSString *filePath = [ALLogger logArrayFilepath];
        NSData *noteData = [NSData dataWithContentsOfFile:filePath];
        NSString *body = [NSString stringWithFormat:@"Hey there sending you the logs. \n Applozic SDK version no.: %@", applozicVersion];
        [mailer setMessageBody:body
                        isHTML:YES];
        [mailer setMailComposeDelegate:self];
        [mailer addAttachmentData:noteData mimeType:@"text/plain" fileName:@"ApplozicLogs.txt"];
        
        [self presentViewController:mailer animated:YES completion:nil];
    }
    else
    {

        [ALUIUtilityClass showAlertMessage:@"Failure" andTitle:@"Your device doesn't support the composer sheet"];

    }
}

//===============================================================================
// TO LAUNCH INDIVIDUAL CHAT
//
//===============================================================================

- (IBAction)mChatLaunchButton:(id)sender {

    ALMessageService *service = [[ALMessageService alloc] init];
    [service getTotalUnreadMessageCountWithCompletionHandler:^(NSUInteger unreadCount, NSError *error) {

        if (error){
            NSLog(@"ERRROR in fetching count");
            return;
        }

        NSLog(@"Current count is now @@ :%lu",(unsigned long)unreadCount);
    }];
}

//===============================================================================
// Multi-Reciever API
//===============================================================================
-(void)sendMessageToMulti
{
    
    ALMessage * multiSendMessage = [[ALMessage alloc] init];
    multiSendMessage.message = @"Broadcasted Message";
    multiSendMessage.contactIds = nil;
    
    NSMutableArray * contactIDsARRAY = [[NSMutableArray alloc] initWithObjects:@"iosdev1",@"iosdev2",@"iosdev3", nil];
    NSMutableArray * groupIDsARRAY = [[NSMutableArray alloc] initWithObjects:@"",nil];
    [ALMessageService multiUserSendMessage:multiSendMessage toContacts:contactIDsARRAY toGroups:groupIDsARRAY withCompletion:^(NSString *json, NSError *error) {
        if(error){
            NSLog(@"Multi User Error: %@", error);
        }
    }];
}

//===============================================================================
// Custom Message Sending API
//===============================================================================

-(void)sendCustomMessageTo:(NSString *)to WithText:(NSString *)text
{
    ALMessage * customMessage = [ALMessageService createCustomTextMessageEntitySendTo:to withText:text];
    
    [[ALMessageService sharedInstance] sendMessages:customMessage withCompletion:^(NSString *message, NSError *error) {
        if(error)
        {
            NSLog(@"Custom Message Send Error: %@", error);
        }
    }];
}

//===============================================================================
// TO LAUNCH SELLER CHAT....
//
//===============================================================================

- (IBAction)launchSeller:(id)sender
{
    if(![ALDataNetworkConnection noInternetConnectionNotification])
    {
        [self.activityView startAnimating];
        ALConversationProxy * newProxy  = [self makeupConversationDetails];
        
        ALChatManager * chatManager = [[ALChatManager alloc] init];
        [chatManager createAndLaunchChatWithSellerWithConversationProxy:newProxy fromViewController:self];
    }
    else
    {
        [ALDataNetworkConnection checkDataNetworkAvailable];
    }
}

//===============================================================================
//  TEXT MESSAGE With META-DATA Sending
//===============================================================================

-(void)sendMessageWithMetaData      // EXAMPLE FOR META DATA
{
    NSMutableDictionary * dictionary = [self getNewMetaDataDictionary];                                    // ADD RECEIVER ID HERE
    
    ALMessage * messageWithMetaData = [ALMessageService createMessageWithMetaData:dictionary andContentType: ALMESSAGE_CONTENT_DEFAULT andReceiverId:@"receiverId" andMessageText:@"MESG WITH META DATA"];
    
    [[ALMessageService sharedInstance] sendMessages:messageWithMetaData withCompletion:^(NSString *message, NSError *error) {
        
        if(error)
        {
            NSLog(@"ERROR IN SENDING MSG WITH META-DATA : %@", error);
            return ;
        }
        // DO ACTION HERE...
        NSLog(@"MSG_RESPONSE :: %@",message);
    }];
}

-(NSMutableDictionary *)getNewMetaDataDictionary      // EXAMPLE FOR META DATA
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"VALUE" forKey:@"KEY"];
    return dict;
}

//===============================================================================
// Creating Conversation Details
//===============================================================================

-(ALConversationProxy *)makeupConversationDetails
{
    ALConversationProxy * alConversationProxy = [[ALConversationProxy alloc] init];
    alConversationProxy.topicId = @"laptop01";
    alConversationProxy.userId = @"adarshk";
    
    // Note : Uncomment following two lines to set SMS fallback's format.
    /*
     [alConversationProxy setSenderSMSFormat:@"SENDER SMS FORMAT"];
     [alConversationProxy setReceiverSMSFormat:@"RECEIVER SMS FORMAT"];
     */
    ALTopicDetail * alTopicDetail = [[ALTopicDetail alloc] init];
    alTopicDetail.title     = @"Mac Book Pro";
    alTopicDetail.subtitle  = @"13' Retina";
    alTopicDetail.link      = @"https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/master/macbookpro.jpg";
    alTopicDetail.key1      = @"Product ID";
    alTopicDetail.value1    = @"mac-pro-r-13";
    alTopicDetail.key2      = @"Price";
    alTopicDetail.value2    = @"Rs.1,04,999.00";
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:alTopicDetail.dictionary options:NSJSONWritingPrettyPrinted error:&error];
    NSString *resultTopicDetails = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    alConversationProxy.topicDetailJson = resultTopicDetails;
    
    return alConversationProxy;
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.activityView stopAnimating];
    [self.activityView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEW_MESSAGE_NOTIFICATION  object:nil];
}


- (IBAction)logoutBtn:(id)sender
{
    ALRegisterUserClientService * alUserClientService = [[ALRegisterUserClientService alloc] init];
    
    if([ALUserDefaultsHandler getDeviceKeyString])
    {
        [alUserClientService logoutWithCompletionHandler:^(ALAPIResponse *response, NSError *error) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}

- (void) insertInitialContacts
{
    
    ALContactService * contactService = [ALContactService new];
    NSMutableArray * conactArray = [NSMutableArray new];
    
    //contact 1
    ALContact *contact1 = [[ALContact alloc] init];
    contact1.userId = @"adarshk";
    contact1.fullName = @"Adarsh Kumar";
    contact1.displayName = @"Adarsh";
    contact1.email = @"github@applozic.com";
    contact1.contactImageUrl = @"https://avatars0.githubusercontent.com/u/5002214?v=3&s=400";
    contact1.contactType= [NSNumber numberWithInt:1];
    [conactArray addObject:contact1];
    
    
    // contact 2
    ALContact *contact2 = [[ALContact alloc] init];
    contact2.userId = @"marvel";
    contact2.fullName = @"abhishek thapliyal";
    contact2.displayName = @"Abhishek";
    contact2.email = @"abhishek@applozic.com";
    contact2.contactImageUrl = nil;
    contact2.localImageResourceName = @"abhishek.jpg";
    contact2.contactImageUrl = nil;
    contact2.contactType= [NSNumber numberWithInt:2];
    [conactArray addObject:contact2];
    
    
    //    Contact -------- Example with json
    
    
    NSString *jsonString =@"{\"userId\": \"applozic\",\"fullName\": \"Applozic\",\"contactNumber\": \"9535008745\",\"displayName\": \"Applozic Support\",\"contactImageUrl\": \"https://cdn-images-1.medium.com/max/800/1*RVmHoMkhO3yoRtocCRHSdw.png\",\"email\": \"devashish@applozic.com\",\"localImageResourceName\":\"sample.jpg\"}";
    ALContact *contact3 = [[ALContact alloc] initWithJSONString:jsonString];
    [conactArray addObject:contact3];
    
    
    
    //     Contact ------- Example with dictonary
    
    
    NSMutableDictionary *demodictionary = [[NSMutableDictionary alloc] init];
    [demodictionary setValue:@"rachel" forKey:@"userId"];
    [demodictionary setValue:@"Rachel Green" forKey:@"fullName"];
    [demodictionary setValue:@"75760462" forKey:@"contactNumber"];
    [demodictionary setValue:@"Rachel" forKey:@"displayName"];
    [demodictionary setValue:@"aman@applozic.com" forKey:@"email"];
    [demodictionary setValue:@"https://raw.githubusercontent.com/AppLozic/Applozic-Android-SDK/master/app/src/main/res/drawable-xxhdpi/girl.jpg" forKey:@"contactImageUrl"];
    [demodictionary setValue:nil forKey:@"localImageResourceName"];
    [demodictionary setValue:[ALUserDefaultsHandler getApplicationKey] forKey:@"applicationId"];
    ALContact *contact4 = [[ALContact alloc] initWithDict:demodictionary];
    [conactArray addObject:contact4];
    
    [contactService updateOrInsertListOfContacts:conactArray];
    
}
-(void)userUpdate:(NSNotification*)userDetails{
    ALUserDetail * user = userDetails.object;
    if(user.connected){
        //NSLog(@"USER_ONLINE:\nName%@\nID:%@",user.displayName,user.userId);
    }
    else{
        //        NSLog(@"USER_OFFLINE:\nName%@\nID:%@",user.displayName,user.userId);
    }
}

- (IBAction)turnNotification:(id)sender
{
    short mode = (self.notificationSwitch.on ? AL_NOTIFICATION_ENABLE : AL_NOTIFICATION_DISABLE);
    //    [ALUserDefaultsHandler setNotificationMode:mode];
    NSLog(@"NOTIFICATION MODE :: %hd",mode);
    [ALRegisterUserClientService updateNotificationMode:mode withCompletion:^(ALRegistrationResponse *response, NSError *error) {
        
        [ALUserDefaultsHandler setNotificationMode:mode] ;
        NSLog(@"UPDATE Notification Mode Response :: %@ Error :: %@",response, error);
    }];
}

-(void)subGroupCODE:(ALChatManager *)chatManager
{
    // CODE FOR SUBGROUP DO NOT USE IT
    
    //    [chatManager launchChatListWithParentKey:[NSNumber numberWithInt:213407] andFromViewController:self];
    
    //
    //        ALChannelService *ss = [ALChannelService new];
    //        [ss createChannel:@"PRD_SGRP202" andParentChannelKey:[NSNumber numberWithInt:1371169] orClientChannelKey:nil andMembersList:@[@"hi0101",@"hi0102"]
    //             andImageLink:nil channelType:PUBLIC andMetaData:nil withCompletion:^(ALChannel *alChannel) {
    //
    //             }];
    //
    
    //    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"SUB GROUP"
    //                                                                              message:@"Add Parent key"
    //                                                                       preferredStyle:UIAlertControllerStyleAlert];
    //
    //    [ALUtilityClass setAlertControllerFrame:alertVC andViewController:self];
    //    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    //
    //    [alertVC addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    //
    //        textField.placeholder = @"Add Parent Key here...";
    //    }];
    //
    //    [alertVC addAction:[UIAlertAction actionWithTitle:@"Open Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    //
    //        UITextField *textField = alertVC.textFields.firstObject;
    //        if(textField.text.length)
    //        {
    //            int parentKey = [textField.text intValue];
    //            if(parentKey)
    //            {
    //                [chatManager launchChatListWithParentKey:[NSNumber numberWithInt:parentKey] andFromViewController:self];
    //            }
    //            else
    //            {
    //                ALChannelService * service = [ALChannelService new];
    //                ALChannel * channel = [service fetchChannelWithClientChannelKey:textField.text];
    //                if(channel)
    //                {
    //                    [chatManager launchChatListWithParentKey:channel.key andFromViewController:self];
    //                }
    //                else
    //                {
    //                    NSLog(@"NO CHANNEL FOUND");
    //                }
    //            }
    //        }
    //    }]];
    //
    //    [self presentViewController:alertVC animated:YES completion:nil];
    
    
    //    NSMutableArray *childList = [NSMutableArray new];
    //    [childList addObject:[NSNumber numberWithInt:1344099]];
    //    [childList addObject:[NSNumber numberWithInt:1344107]];
    //    ALChannelService *ss = [ALChannelService new];
    //    [ss updateChannel:[NSNumber numberWithInt:1344096] andNewName:nil
    //          andImageURL:nil orClientChannelKey:nil orChildKeys:childList withCompletion:^(NSError *error) {
    //
    //    }];
    
    
    // ADDING
    
    //    NSMutableArray *childList = [NSMutableArray new];
    //    [childList addObject:[NSNumber numberWithInt:1261256]];
    //    [childList addObject:[NSNumber numberWithInt:213407]];
    //    ALChannelService *ss = [ALChannelService new];
    //    [ss addChildKeyList:childList andParentKey:[NSNumber numberWithInt:1371169] withCompletion:^(id json, NSError *error) {
    //
    //    }];
    
    //    [ss removeChildKeyList:childList andParentKey:[NSNumber numberWithInt:213110] withCompletion:^(id json, NSError *error) {
    //
    //    }];
    //    m2 : 1397150
    
    //    clinet channels
    //    NSMutableArray *childList = [@[@"1315217",@"1321170"] mutableCopy];
    
    //    [ss addClientChildKeyList:childList andParentKey:@"1170818" withCompletion:^(id json, NSError *error) {
    //
    //    }];
    
    //    [ss removeClientChildKeyList:childList andParentKey:@"1170818" withCompletion:^(id json, NSError *error) {
    //
    //    }];
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:@"userUpdate"];
}

@end
