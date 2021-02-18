//
//  ALSettingsForDebug.m
//  applozicdemo
//
//  Created by Divjyot Singh on 16/05/16.
//  Copyright © 2016 applozic Inc. All rights reserved.
//

#import "ALSettingsForDebug.h"
#import  <Applozic/ALChatViewController.h>
#import "ALChatManager.h"
#import "ApplozicLoginViewController.h"
#import <ApplozicCore/ApplozicCore.h>

@interface ALSettingsForDebug () <UITextFieldDelegate,UIPickerViewDelegate, UIPickerViewDataSource>

@end

@implementation ALSettingsForDebug{
    BOOL isContextChat;
    BOOL isBackgroundWallpaperSet;
    BOOL isNotificationEnabled;
    NSString * moduleID;
    NSString * applicationID;
    NSString * environment;
    
    NSArray * environmentNamesArray;
    NSArray * environmentURLArray;
    NSInteger pickerRowSelected;
    BOOL toggle;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.environmentPickerView.dataSource=self;
    self.environmentPickerView.delegate=self;
    self.environmentPickerView.hidden = YES;
    toggle = self.environmentPickerView.hidden;
    
    environmentNamesArray = [[NSArray alloc] initWithObjects:@"apps",@"apps-test",@"staging",@"chat", nil];
    environmentURLArray = [[NSArray alloc] initWithObjects:@"https://apps.applozic.com",
                           @"https://apps-test.applozic.com",
                           @"https://staging.applozic.com",
                           @"https://chat.applozic.com", nil];

    self.moduleIDTextField.delegate = self;
    
    [self.selectedEnvirnLabel setUserInteractionEnabled:YES];
    self.selectedEnvirnLabel.layer.borderColor = [UIColor colorWithRed:1 green:0.682 blue:0.102 alpha:1].CGColor; /*#ffae1a*/
    self.selectedEnvirnLabel.layer.borderWidth = 2.0;

    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectEnvironment)];
    [self.selectedEnvirnLabel addGestureRecognizer:tapGesture];
    
    

    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    [self fetchAllSettings];
    [self setAllSettings];

}
- (IBAction)setContextualChatSwitch:(id)sender {
    [ALApplozicSettings setContextualChat:self.contextualChatSwitchOutlet.on];
}

- (IBAction)backgroundWallaperSwitchAction:(id)sender {
    [ALApplozicSettings setChatWallpaperImageName:(self.backWallaperSwitchOutlet.on?@"wallpaper.png":@"NULL")];
}
- (IBAction)doneButtonAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    if(![textField.text isEqualToString:@""]){
        [ALUserDefaultsHandler setAppModuleName:self.moduleIDTextField.text];
    }
    return YES;
}


-(void)fetchAllSettings {
    //FETCHING
    environment = [ALUserDefaultsHandler getBASEURL];
    isContextChat = [ALApplozicSettings getContextualChatOption];
    isBackgroundWallpaperSet = (([[ALApplozicSettings getChatWallpaperImageName] isEqualToString:@"NULL"]
                                 ||[ALApplozicSettings getChatWallpaperImageName]== NULL ) ? NO : YES);
    isNotificationEnabled =
    ([ALUserDefaultsHandler getNotificationMode] == AL_NOTIFICATION_ENABLE
     ?YES:NO);
    
    
}

-(void)setAllSettings{
    //SETTING
    self.selectedEnvirnLabel.text = environment;
    [self.contextualChatSwitchOutlet setOn:isContextChat];
    [self.backWallaperSwitchOutlet setOn:isBackgroundWallpaperSet];
    [self.turnNotificationSwitch setOn:isNotificationEnabled];
}

////PICKER VIEW DELEGATES
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;

}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return environmentURLArray.count;
    
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return environmentURLArray[row];
}

-(void)selectEnvironment{
    toggle = !toggle;
    self.environmentPickerView.hidden = toggle;
    
    //Setting selected pickerview row to label
    pickerRowSelected = (long)[self.environmentPickerView selectedRowInComponent:0];
    
    
    [self setEnvironment:environmentNamesArray[pickerRowSelected]];
}

-(void)setEnvironment:(NSString*)envrn{
    
    self.selectedEnvirnLabel.text = environmentURLArray[pickerRowSelected];
    
    NSString * alKBASE_URL=[NSString stringWithFormat:@"https://%@.applozic.com",envrn];
    
    NSString * alMQTT_URL = [NSString stringWithFormat:@"%@.applozic.com",envrn];
    
    NSString * alFILE_URL = [NSString stringWithFormat:@"https://%@.com",([envrn isEqualToString:@"apps"]||[envrn isEqualToString:@"chat"])?@"applozic":@"mobi-com-alpha.appspot"];
    
    
    [ALUserDefaultsHandler setBASEURL:alKBASE_URL];
    [ALUserDefaultsHandler setMQTTURL:alMQTT_URL];
    [ALUserDefaultsHandler setFILEURL:alFILE_URL];
    [ALUserDefaultsHandler setMQTTPort:@"1883"];
    
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component{
    
    [self setEnvironment:environmentNamesArray[row]];
    
}
- (IBAction)turnNotification:(id)sender {
}

@end



