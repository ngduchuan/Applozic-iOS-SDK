//
//  ContinerViewController.m
//  applozicdemo
//
//  Created by apple on 08/03/21.
//  Copyright © 2021 applozic Inc. All rights reserved.
//

#import "ContinerListViewController.h"
#import <Applozic/Applozic.h>

@implementation ContinerListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigation];
    [self setupView];
}

-(void)setupView {

    UIView * containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:containerView];

    [containerView.leadingAnchor constraintEqualToAnchor: self.view.leadingAnchor].active = true;
    [containerView.trailingAnchor constraintEqualToAnchor: self.view.trailingAnchor].active = true;
    [containerView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = true;
    [containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = true;

    // Add child view controller view to container
    NSBundle * bundle = [NSBundle bundleForClass:ALMessagesViewController.class];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName: @"Applozic" bundle:bundle];
    UIViewController * controller = [storyboard instantiateViewControllerWithIdentifier:@"ALViewController"];
    [self addChildViewController: controller];
    controller.view.translatesAutoresizingMaskIntoConstraints = false;
    [containerView addSubview:controller.view];

    [controller.view.leadingAnchor constraintEqualToAnchor: containerView.leadingAnchor].active = true;
    [controller.view.trailingAnchor constraintEqualToAnchor: containerView.trailingAnchor].active = true;
    [controller.view.topAnchor constraintEqualToAnchor:containerView.topAnchor].active = true;
    [controller.view.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor].active = true;
    [controller didMoveToParentViewController:self];

}

-(void)setupNavigation {

    /// Title of the chat list
    self.navigationItem.title = [ALApplozicSettings getTitleForConversationScreen];

    /// Left bar  back button item
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self customBackButton:[ALApplozicSettings getTitleForBackButtonMsgVC]]];
    [self.navigationItem setLeftBarButtonItem:backButtonItem];

    /// Right bar  back button item
    UIBarButtonItem *startNewConversationButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                                target:self
                                                                                                action:@selector(startNewConversation:)];
    [self.navigationItem setRightBarButtonItem:startNewConversationButton];
}

/// Custom back button
-(UIView *)customBackButton:(NSString *)text {

    UIImageView *imageView = [[UIImageView alloc] initWithImage: [ALUIUtilityClass getImageFromFramworkBundle:@"bbb.png"]];
    [imageView setFrame:CGRectMake(-10, 0, 30, 30)];
    [imageView setTintColor:[UIColor whiteColor]];
    UILabel *label=[[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width - 5, imageView.frame.origin.y + 5 , 20, 15)];
    [label setTextColor: [ALApplozicSettings getColorForNavigationItem]];
    [label setText:text];
    [label sizeToFit];

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width + label.frame.size.width, imageView.frame.size.height)];
    view.bounds=CGRectMake(view.bounds.origin.x+8, view.bounds.origin.y-1, view.bounds.size.width, view.bounds.size.height);
    [view addSubview:imageView];
    [view addSubview:label];

    UITapGestureRecognizer * backTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backAction:)];
    backTap.numberOfTapsRequired = 1;
    [view addGestureRecognizer:backTap];
    return view;
}

-(void)backAction:(id)sender {
    UIViewController *  uiController = [self.navigationController popViewControllerAnimated:YES];
    if(!uiController){
        [self  dismissViewControllerAnimated:YES completion:nil];
    }
}

/// This method will open the contacts screen for starting new chat
-(void)startNewConversation:(id)sender {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALNewContactsViewController *contactVC = (ALNewContactsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    contactVC.forGroup = [NSNumber numberWithInt:0];
    [self.navigationController pushViewController:contactVC animated:YES];
}

@end
