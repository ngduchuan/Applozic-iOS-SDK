//
//  ApplozicLoginViewController.m
//  applozicdemo
//
//  Created by Devashish on 08/10/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ApplozicLoginViewController.h"
#import <Applozic/ALUser.h>
#import <Applozic/ALUserDefaultsHandler.h>
#import <Applozic/ALMessageClientService.h>
#import <Applozic/ALRegistrationResponse.h>
#import <Applozic/ALRegisterUserClientService.h>
#import <Applozic/ALMessagesViewController.h>
#import <Applozic/ALApplozicSettings.h>
#import <Applozic/ALDataNetworkConnection.h>
#import <Applozic/ALChatLauncher.h>
#import <Applozic/ALMessageDBService.h>
#import "ALChatManager.h"
#import "LaunchChatFromSimpleViewController.h"

@interface ApplozicLoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userIdField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *getStarted;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *mActivityIndicator;

@end

@implementation ApplozicLoginViewController


//-------------------------------------------------------------------------------------------------------------------
//      View lifecycle
//-------------------------------------------------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    //[ self registerForNotification];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        self.userIdField.textAlignment = NSTextAlignmentRight;
        self.emailField.textAlignment = NSTextAlignmentRight;
        self.passwordField.textAlignment = NSTextAlignmentRight;
    }
    
    [self.getStarted setTitle: NSLocalizedStringWithDefaultValue(@"getStarted", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Get Started", @"") forState:UIControlStateNormal]; // To set the title
    self.userIdField.placeholder = NSLocalizedStringWithDefaultValue(@"userId", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"UserId", @"");
    self.emailField.placeholder = NSLocalizedStringWithDefaultValue(@"email", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Email", @"");
    self.passwordField.placeholder = NSLocalizedStringWithDefaultValue(@"password", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Password", @"");
    
}

- (void)viewWillAppear:(BOOL)animated {
//    if (![ALUserDefaultsHandler getApnDeviceToken]){
//        [ self registerForNotification];
//    }
    
    [super viewWillAppear:animated];
    
    [self registerForKeyboardNotifications];
    
    [ALDataNetworkConnection checkDataNetworkAvailable];
    [self.mActivityIndicator stopAnimating];
    [self setTitle:NSLocalizedStringWithDefaultValue(@"logoutLabelText", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Logout", @"")];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self deregisterFromKeyboardNotifications];
    
    [super viewWillDisappear:animated];
    
}

- (void)registerForKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)deregisterFromKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    
    NSDictionary* info = [notification userInfo];
    
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGPoint buttonOrigin = self.getStarted.frame.origin;
    
    CGFloat buttonHeight = self.getStarted.frame.size.height;
    
    CGRect visibleRect = self.view.frame;
    
    visibleRect.size.height -= keyboardSize.height;
    
    if (!CGRectContainsPoint(visibleRect, buttonOrigin)){
        
        CGPoint scrollPoint = CGPointMake(0.0, buttonOrigin.y - visibleRect.size.height + buttonHeight);
        
        [self.scrollView setContentOffset:scrollPoint animated:YES];
        
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

//-------------------------------------------------------------------------------------------------------------------
//      IBAction func
//-------------------------------------------------------------------------------------------------------------------

- (IBAction)login:(id)sender {
    
     if([ALUserDefaultsHandler isLoggedIn])
     {
        ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
        [registerUserClientService logoutWithCompletionHandler:^(ALAPIResponse *response, NSError *error) {
            
        }];
     }
    // Initial login view .....
    
    NSString *message = [[NSString alloc] initWithFormat: @"Hello %@", [self.userIdField text]];
    NSLog(@"message: %@", message);
    
    if (self.userIdField.text.length == 0)
    {
        [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"userIdEmpty", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"UserId can't be blank frnce", @"")andTitle: NSLocalizedStringWithDefaultValue(@"error", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Error", @"")];
        return;
    }
    
    if (self.passwordField.text.length == 0)
    {
        [ALUtilityClass showAlertMessage:NSLocalizedStringWithDefaultValue(@"passwordEmpty", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Password can't be blank ", @"")
                                andTitle:NSLocalizedStringWithDefaultValue(@"error", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Error", @"")];
        return;
    }

    
    ALUser * user = [[ALUser alloc] init];
    [user setUserId:[self.userIdField text]];
    [user setEmail:[self.emailField text]];
    [user setPassword:[self.passwordField text]];
    [user setAuthenticationTypeId:(short)APPLOZIC];
    [self.mActivityIndicator startAnimating];
    [ALUserDefaultsHandler setUserAuthenticationTypeId:(short)APPLOZIC];
    [ALUserDefaultsHandler setUserId:user.userId];
    [ALUserDefaultsHandler setEmailId:user.email];
    [ALUserDefaultsHandler setPassword:user.password];
    ALChatManager * chatManager = [[ALChatManager alloc] init];
    [chatManager connectUserWithCompletion:user withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {

        [self.mActivityIndicator stopAnimating];
        if (!error)
        {
            UIStoryboard* storyboardM = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *launchChat = [storyboardM instantiateViewControllerWithIdentifier:@"LaunchChatFromSimpleViewController"];
            launchChat.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:launchChat animated:YES completion:nil];
        }
    }];
}

//-------------------------------------------------------------------------------------------------------------------
//     Textfield delegate methods
//-------------------------------------------------------------------------------------------------------------------

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userIdField) {
        [self.emailField becomeFirstResponder];
    }
    else if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    }
    else {
        //TODO: Also validate user Id and email is entered.
        [textField resignFirstResponder];
    }
    return true;
}

- (IBAction)getstarted:(id)sender {
}

@end
