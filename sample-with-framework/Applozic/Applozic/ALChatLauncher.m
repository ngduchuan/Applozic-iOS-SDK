//
//  ALChatLauncher.m
//  Applozic
//
//  Created by devashish on 21/12/2015.
//  Copyright © 2015 applozic Inc. All rights reserved.
//


#import "ALChatLauncher.h"
#import "ALChatViewController.h"
#import "ALMessagesViewController.h"
#import "ALUIUtilityClass.h"

const int REGULAR_CONTACTS = 0;

@interface ALChatLauncher ()<ALChatViewControllerDelegate, ALMessagesViewDelegate>

@end

@implementation ALChatLauncher


- (instancetype)initWithApplicationId:(NSString *) applicationId;
{
    self = [super init];
    if (self)
    {
        self.applicationId = applicationId;
    }
    return self;
}

/**
 * Get navigation controller to launch depend on settings.
 **/

- (UINavigationController *)createNavigationControllerForVC:(UIViewController *)vc
{
    NSString * className = [ALApplozicSettings getCustomNavigationControllerClassName];
    if (![className isKindOfClass:[NSString class]]) className = @"UINavigationController";
    UINavigationController * navC = [(UINavigationController *)[NSClassFromString(className) alloc] initWithRootViewController:vc];
    return navC;
}

-(void)launchIndividualChat:(NSString *)userId withGroupId:(NSNumber*)groupID
    andViewControllerObject:(UIViewController *)viewController andWithText:(NSString *)text
{
    self.chatLauncherFLAG = [NSNumber numberWithInt:1];
    
    if(groupID){
        [self launchIndividualChatForGroup:userId withGroupId:groupID withDisplayName:nil andViewControllerObject:viewController andWithText:text];
    }else{
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
        
        ALChatViewController * chatView = (ALChatViewController *) [storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        
        chatView.channelKey = groupID;
        chatView.contactIds = userId;
        chatView.text = text;
        chatView.individualLaunch = YES;
        chatView.chatViewDelegate = self;
        chatView.isSearch = NO;
        ALSLog(ALLoggerSeverityInfo, @"CALLED_VIA_NOTIFICATION");
        
        UINavigationController * conversationViewNavController = [self createNavigationControllerForVC:chatView];
        conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        conversationViewNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [viewController presentViewController:conversationViewNavController animated:YES completion:nil];
    }
}

/**
 * Use this to launch individual chat using conversationId.
 */
-(void)launchIndividualChat:(NSString *)userId withGroupId:(NSNumber*)groupID withConversationId:(NSNumber *)conversationId
    andViewControllerObject:(UIViewController *)viewController andWithText:(NSString *)text
{
    self.chatLauncherFLAG = [NSNumber numberWithInt:1];
    
    if(groupID){
        [self launchIndividualChatForGroup:userId withGroupId:groupID withDisplayName:nil andViewControllerObject:viewController andWithText:text];
    }else{
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
        
        ALChatViewController * chatView = (ALChatViewController *) [storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        
        chatView.channelKey = groupID;
        chatView.contactIds = userId;
        chatView.conversationId = conversationId;
        chatView.text = text;
        chatView.individualLaunch = YES;
        chatView.chatViewDelegate = self;
        ALSLog(ALLoggerSeverityInfo, @"CALLED_VIA_NOTIFICATION");
        
        UINavigationController * conversationViewNavController = [self createNavigationControllerForVC:chatView];
        conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        conversationViewNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [viewController presentViewController:conversationViewNavController animated:YES completion:nil];
    }
}

-(void)launchIndividualChat:(NSString *)userId withGroupId:(NSNumber*)groupID
            withDisplayName:(NSString*)displayName
    andViewControllerObject:(UIViewController *)viewController andWithText:(NSString *)text
{
    
    if( groupID){
        [self launchIndividualChatForGroup:userId withGroupId:groupID withDisplayName:displayName andViewControllerObject:viewController andWithText:text];
    }else{
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic"
                                    
                                                             bundle:[NSBundle bundleForClass:ALChatViewController.class]];
        ALChatViewController *chatView = (ALChatViewController *) [storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        chatView.channelKey = groupID;
        chatView.contactIds = userId;
        chatView.text = text;
        chatView.individualLaunch = YES;
        chatView.displayName = displayName;
        chatView.chatViewDelegate = self;
        chatView.isSearch = NO;
        
        UINavigationController *conversationViewNavController = [self createNavigationControllerForVC:chatView];
        conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        conversationViewNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve ;
        [viewController presentViewController:conversationViewNavController animated:YES completion:nil];
    }
}

-(void)launchIndividualChatForGroup:(NSString *)userId
                        withGroupId:(NSNumber *)groupID
                    withDisplayName:(NSString*)displayName
            andViewControllerObject:(UIViewController *)viewController andWithText:(NSString *)text
{
    
    ALChannelService *channelService = [ALChannelService new];

    [channelService getChannelInformationByResponse:groupID
                                 orClientChannelKey:nil
                                     withCompletion:^(NSError *error,
                                                      ALChannel *channel,
                                                      ALChannelFeedResponse *channelResponse) {

        if (error) {
            NSLog(@"Failed to launch the channel conversation %@", error.localizedDescription);
            return;
        }

        if (!channel) {
            NSLog(@"Failed to launch the channel conversation due to some error");
            return;
        }

        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic"

                                                             bundle:[NSBundle bundleForClass:ALChatViewController.class]];

        ALChatViewController *chatView = (ALChatViewController *) [storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];

        chatView.channelKey = groupID;
        chatView.text = text;
        chatView.contactIds = userId;
        chatView.individualLaunch = YES;
        chatView.displayName = displayName;
        chatView.chatViewDelegate = self;
        chatView.isSearch = NO;

        UINavigationController *conversationViewNavController = [self createNavigationControllerForVC:chatView];
        conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        conversationViewNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve ;
        [viewController presentViewController:conversationViewNavController animated:YES completion:nil];

    }];
}


-(void)launchChatList:(NSString *)title andViewControllerObject:(UIViewController *)viewController
{
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    UITabBarController *theTabBar = [storyboard instantiateViewControllerWithIdentifier:@"messageTabBar"];
    
    UITabBarController * tabBAR = ((UITabBarController *)theTabBar);
    [self setCustomTabBarIcon:tabBAR];
    UINavigationController * navBAR = (UINavigationController *)[[tabBAR viewControllers] objectAtIndex:0];
    ALMessagesViewController * msgVC = (ALMessagesViewController *)[[navBAR viewControllers] objectAtIndex:0];
    msgVC.messagesViewDelegate = self;
    
    [[theTabBar tabBar] setBarTintColor:[ALApplozicSettings getTabBarBackgroundColour]];
    [theTabBar.view setTintColor:[ALApplozicSettings getTabBarSelectedItemColour]];
    
    if ([tabBAR.tabBar respondsToSelector:@selector(setUnselectedItemTintColor:)])
    {
        [tabBAR.tabBar setUnselectedItemTintColor:[ALApplozicSettings getTabBarUnSelectedItemColour]];
    }

    theTabBar.modalPresentationStyle = UIModalPresentationFullScreen;
    [viewController presentViewController:theTabBar animated:YES completion:nil];
    
}

-(void)launchContactList:(UIViewController *)uiViewController
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    
    ALNewContactsViewController *contcatVC = (ALNewContactsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    contcatVC.directContactVCLaunch = YES;
    UINavigationController *conversationViewNavController = [[UINavigationController alloc] initWithRootViewController:contcatVC];
    conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    [uiViewController presentViewController:conversationViewNavController animated:YES completion:nil];
}

-(void)launchIndividualContextChat:(ALConversationProxy *)conversationProxy andViewControllerObject:(UIViewController *)viewController
                   userDisplayName:(NSString *)displayName andWithText:(NSString *)text
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic"
                                                         bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    
    ALChatViewController * contextChatView = (ALChatViewController*) [storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
    
    contextChatView.displayName      = displayName;
    contextChatView.conversationId   = conversationProxy.Id;
    
    if(conversationProxy.userId != nil)
    {
        contextChatView.contactIds  = conversationProxy.userId;
        contextChatView.channelKey   = nil;
    }
    else
    {
        contextChatView.channelKey   = conversationProxy.groupId;
        contextChatView.contactIds  = nil;
    }
    contextChatView.text             = text;
    contextChatView.individualLaunch = YES;
    
    UINavigationController *conversationViewNavController = [self createNavigationControllerForVC:contextChatView];
    conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    conversationViewNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [viewController presentViewController:conversationViewNavController animated:YES completion:nil];
}

-(void)launchChatListWithUserOrGroup:(NSString *)userId withChannel:(NSNumber*)channelKey andViewControllerObject:(UIViewController *)viewController
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALMessagesViewController *chatListView = (ALMessagesViewController*)[storyboard instantiateViewControllerWithIdentifier:@"ALViewController"];
    UINavigationController *conversationViewNavController = [self createNavigationControllerForVC:chatListView];
    
    chatListView.userIdToLaunch = userId;
    chatListView.channelKey = channelKey;
    chatListView.messagesViewDelegate = self;
    conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    [viewController presentViewController:conversationViewNavController animated:YES completion:nil];
    
}

//  WHEN FLOW IS FROM MESSAGEVIEW TO CHATVIEW
-(void)handleCustomActionFromMsgVC:(UIViewController *)chatView andWithMessage:(ALMessage *)alMessage
{
    id launcherDelegate = NSClassFromString([ALApplozicSettings getCustomClassName]);
    [launcherDelegate handleCustomAction:chatView andWithMessage:alMessage];
}

//  WHEN FLOW IS FROM DIRECT CHATVIEW
-(void)handleCustomActionFromChatVC:(UIViewController *)chatViewController andWithMessage:(ALMessage *)alMessage
{
    id launcherDelegate = NSClassFromString([ALApplozicSettings getCustomClassName]);
    [launcherDelegate handleCustomAction:chatViewController andWithMessage:alMessage];
}


-(void)launchChatListWithCustomNavigationBar:(UIViewController *)viewController
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    
    ALMessagesViewController *chatListView = (ALMessagesViewController*)[storyboard instantiateViewControllerWithIdentifier:@"ALViewController"];
    
    NSString * className = [ALApplozicSettings getCustomNavigationControllerClassName];
    if (![className isKindOfClass:[NSString class]]) className = @"UINavigationController";
    
    UINavigationController * navC = [(UINavigationController *)[NSClassFromString(className) alloc] initWithRootViewController:chatListView];
    navC.modalPresentationStyle = UIModalPresentationFullScreen;
    [viewController presentViewController:navC animated:YES completion:nil];
    
}

//==========================================================================================================================================
#pragma mark : ALMSGVC LAUNCH FOR SUB GROUPS
//==========================================================================================================================================

-(void)launchChatListWithParentKey:(NSNumber *)parentKey andViewControllerObject:(UIViewController *)viewController
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    UIViewController *theTabBar = [storyboard instantiateViewControllerWithIdentifier:@"messageTabBar"];
    
    UITabBarController * tabBAR = ((UITabBarController *)theTabBar);
    UINavigationController * navBAR = (UINavigationController *)[[tabBAR viewControllers] objectAtIndex:0];
    ALMessagesViewController * msgVC = (ALMessagesViewController *)[[navBAR viewControllers] objectAtIndex:0];
    msgVC.messagesViewDelegate = self;
    
    ALChannelService *channelService = [ALChannelService new];

    [channelService getChannelInformationByResponse:parentKey
                                 orClientChannelKey:nil
                                     withCompletion:^(NSError *error,
                                                      ALChannel *channel,
                                                      ALChannelFeedResponse *channelResponse) {

        if (error ||
            !channel) {
            return;
        }

        msgVC.parentGroupKey = parentKey;
        [msgVC intializeSubgroupMessages];
        theTabBar.modalPresentationStyle = UIModalPresentationFullScreen;
        [viewController presentViewController:theTabBar animated:YES completion:nil];
    }];
}

//==========================================================================================================================================
#pragma mark : CUSTOM TAB BAR ICON METHOD
//==========================================================================================================================================

-(void)setCustomTabBarIcon:(UITabBarController *)tabBAR
{
    UITabBarItem *item1 = [tabBAR.tabBar.items objectAtIndex:0];
    [item1 setTitle:[ALApplozicSettings getChatListTabTitle]];
    UIImage *chatCustomImg = [ALApplozicSettings getChatListTabIcon];
    UIImage *defaultImg = [ALUIUtilityClass getImageFromFramworkBundle:@"chat_default.png"];
    UIImage *chatIcon = chatCustomImg ? chatCustomImg : defaultImg;
    [item1 setImage:chatIcon];
    
    UITabBarItem *item2 = [tabBAR.tabBar.items objectAtIndex:1];
    [item2 setTitle:[ALApplozicSettings getProfileTabTitle]];
    UIImage *profileCustomImg = [ALApplozicSettings getChatListTabIcon];
    UIImage *defaultProfileImg = [ALUIUtilityClass getImageFromFramworkBundle:@"contact_default.png"];
    UIImage *profileIcon = profileCustomImg ? profileCustomImg : defaultProfileImg;
    [item2 setImage:profileIcon];
}

//============================================
// launching contact screen with message
//============================================

-(void)launchContactScreenWithMessage:(ALMessage *)alMessage andFromViewController:(UIViewController *)viewController
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALNewContactsViewController *contactVC = (ALNewContactsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    contactVC.directContactVCLaunch = YES;
    contactVC.alMessage = alMessage;
    contactVC.forGroup = [NSNumber numberWithInt:REGULAR_CONTACTS];

    UINavigationController * conversationViewNavController = [self createNavigationControllerForVC:contactVC];
    conversationViewNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    conversationViewNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    [viewController presentViewController:conversationViewNavController animated:YES completion:nil];
}

@end

