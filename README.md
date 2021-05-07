# Applozic-iOS-SDK
iOS Chat SDK

### Overview         

Open source iOS Chat and Messaging SDK that lets you add real time messaging in your mobile (android, iOS) applications and website.

Signup at [https://www.applozic.com/signup.html](https://www.applozic.com/signup.html?utm_source=github&utm_medium=readme&utm_campaign=ios) to get the App ID.


## Introduction :cyclone:         

Applozic brings real-time engagement with chat, video, and voice to your web,
mobile, and conversational apps. We power emerging startups and established
companies with the most scalable and powerful chat APIs, enabling application
product teams to drive better user engagement, and reduce time-to-market.

Customers and developers from over 50+ countries use us and love us, from online
marketplaces and eCommerce to on-demand services, to Education Tech, Health
Tech, Gaming, Live-Streaming, and more.

Our feature-rich product includes robust client-side SDKs for iOS, Android, React
Native, and Flutter. We also support popular server-side languages, a beautifully
customizable UI kit, and flexible platform APIs.

Chat, video, and audio-calling have become the new norm in the post-COVID era,
and we're bridging the gap between businesses and customers by delivering those
exact solutions.

## Table of Contents :beginner:

* [Prerequisites](#prerequisites)
* [Quick Start](#quickstart)
   * [Setting Up Xcode for new project](#setting-xcode-project)
   * [Integrating SDK in your App](setup-sdk)
* [Announcements](#announcements)
* [Roadmap](#roadmap)
* [Features](#feature)
* [About](#about)
* [License](#license)

<a name="prerequisites"></a>
## Prerequisites :crystal_ball:

- Install the following:

  * [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) 12.0 or later
  * [CocoaPods](https://cocoapods.org/) 1.9.0 or later

- Make sure that your project meets these requirements:

  * Your project must target iOS 10 or later.
  *  Set up a physical or simulator iOS device to run your app
- [Sign-Up](https://www.applozic.com/signup.html?utm_source=github&utm_medium=readme&utm_campaign=ios) or Login to get your Applozic's [API key/App Id](https://console.applozic.com/settings/install). <br>

<a name="quickstart"></a>
## Quick Start :rocket:

Before getting started with installation. We recommend to go through some basic documentation for [Applozic iOS Chat & Messaging SDK Documentation](https://www.applozic.com/docs/ios-chat-sdk.html?utm_source=github&utm_medium=readme&utm_campaign=ios) :memo: <br>

<a name="setting-xcode-project"></a>
### Setting up Xcode project

* Open Xcode Create a new project **Select App** and Click Next 
* Set the Product Name as per your preference (we will name it as **applozic-first-app**) and click Next and Select folder then Create.

<a name="setup-sdk"></a>
### 1. Setup

### Include the Applozic SDK for iOS in an Existing Application

The iOS Applozic framework can be installed using CocoaPods or Dynamic Frameworks, as you prefer.

### CocoaPods

Applozic is available through [CocoaPods](https://cocoapods.org). To install
it

1. Open Terminal
2. Navigate to the root directory of your Project (the directory where your *.xcodeproj file is)
3. Run command
```sh
pod init
```

Again go to your Project's root directory, click on the "Podfile" to open.
Copy-paste the following code in the file and Save

```ruby
source 'https://github.com/CocoaPods/Specs'
use_frameworks!  # Required to add 
platform :ios, '10.0'

target 'TARGET_NAME' do
    pod 'Applozic'  # Required to add 
end
```

4. Go to your project directory where Podfile there run `pod install` or `pod update` from terminal to refresh the CocoaPods dependencies.

5. Open your project newly generated `*.xcworkspace` or existing and build your project.

### Frameworks

#### XCFramework setup

1. Download the Applozic latest Chat frameworks from [here](https://github.com/AppLozic/Applozic-iOS-SDK/tree/master/Frameworks)
2. Uncompress the ZIP files inside Debug or Release Applozic and ApplozicCore framework.
3. On your application `targets` General settings tab, in the `Frameworks, libraries, and embedded content`, drag and drop each xcframework you want to use from the downloaded folder.
4. Make sure `Always Embed Swift Standard Libraries` is `YES` in the build settings of your project.


### Add Permissions

App Store requires any app which accesses camera, contacts, gallery, location, a microphone to add the description of why does your app needs to access these features.

In the Info.plist file of your project. Please add the following permissions

```
 <key>NSCameraUsageDescription</key>
 <string>Allow Camera</string>
 <key>NSContactsUsageDescription</key>
 <string>Allow Contacts</string>
 <key>NSLocationWhenInUseUsageDescription</key>
 <string>Allow location sharing!!</string>
 <key>NSMicrophoneUsageDescription</key>
 <string>Allow MicroPhone</string>
 <key>NSPhotoLibraryUsageDescription</key>
 <string>Allow Photos</string>
 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>Allow write access</string>
```

### Importing Methods for Authentication

The method file that we need here is `ALChatManager` files.

1. Download the `ALChatManager.h` [here](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/master/sample-with-framework/applozicdemo/ALChatManager.h) and `ALChatManager.m` [here](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/master/sample-with-framework/applozicdemo/ALChatManager.m)
2. Add the Downloaded ALChatManager.h and ALChatManager.m in your project 
3. Open `ALChatManager.h` file in your Xcode and Replace "applozic-sample-app" with your App ID from [here](https://console.applozic.com/settings/install)


### 2. Register/Login the User

```objc
// Creating "ALUser" and Passing user details
// Except UserId all the other parameters are optional

ALUser *alUser = [[ALUser alloc] init];
[alUser setUserId:@"testUser"]; //NOTE : +,*,? are not allowed chars in userId.
[alUser setDisplayName:@"Applozic Test"]; // Display name of user 
[alUser setContactNumber:@""];// formatted contact no
[alUser setImageLink:@"user_profile_image_link"];// User's profile image link.
[alUser setPassword:@"testpassword"]; //Password for the user

//Saving the details
[ALUserDefaultsHandler setUserId:alUser.userId];
[ALUserDefaultsHandler setEmailId:alUser.email];
[ALUserDefaultsHandler setDisplayName:alUser.displayName];
[ALUserDefaultsHandler setUserAuthenticationTypeId:(short)APPLOZIC];
[ALUserDefaultsHandler setPassword:alUser.password];

// Registering or Loging in the User
 ALChatManager * chatManager = [[ALChatManager alloc] init];
 [chatManager connectUserWithCompletion:alUser withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {
        
      if (!error) {
        // Applozic registration successful
      } else {
          NSLog(@"Error in Applozic registration : %@",error.description);
      }
}];
```

### 3. Push notification

#### Setting up APNs Certificates
Applozic sends the payload to Apple servers which then sends the Push notification to your user's device.

#### Creating APNs certificates

For Apple to send these notifications, would have to create an APNs certificate in your Apple developer account.

1. Visit this [link](https://developer.apple.com/account/resources/certificates/add), to create Apple Push Notification service SSL (Sandbox) i.e development certificate

   ![apns-development-certificate](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/apns-development-certificate.png "apns-development-certificate")


2. Visit this [link](https://developer.apple.com/account/resources/certificates/add), to create Apple Push Notification service SSL (Sandbox & Production) i.e distribution certificate

   ![apns-distribution-certificate](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/apns-distribution.png "apns-distribution-certificate")


Once the certificates are created you can download them and export the p12 files with password for development and distribution certificate either from Keychain Acess from Mac.  


#### Upload APNs Certificates

Upload your push notification certificates (mentioned above) to the Applozic console by referring to the below-given image.

Go to Applozic [console](https://console.applozic.com/settings/pushnotification) push notification section to upload the APNs development and distribution certificates

   ![apns-certificate-upload](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-Audio-Video-SDK/main/Images/apns-certificate-upload.png
 "apns-certificate-upload")


#### Adding Capabilities to Your App

Add capabilities to configure app services from Apple, such as push notifications, Background modes

1. On the Xcode project’s Signing & Capabilities tab, Click (+ Capability) to add “Push Notifications”

2. Next Click (+ Capability) to add "Background modes" enable this below four options from Background modes

 * "Background fetch"
 * "Remote notifications"
 
Following screenshot would be of help.

![xcode-capability](https://raw.githubusercontent.com/AppLozic/Applozic-iOS-SDK/main/Images/xcode-capability.png
 "xcode-capability")
 
#### Configure the push notification in the Appdelegate file of your project.

Add the below imports in the Appdelegate file

```objc
#import <Applozic/Applozic.h>
#import <UserNotifications/UserNotifications.h>
```

##### Handling app launch on notification click and register remote notification for APNs

Add the following code in AppDelegate.m class, this function will be called after the app launch to register for push notifications.

```objc

// UNUserNotificationCenterDelegate are required for APNs call backs please add this delegate to your AppDelegate file 
@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end


// didFinishLaunchingWithOptions method of your app

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // checks wheather app version is updated/changed then makes server call setting VERSION_CODE
    [ALRegisterUserClientService isAppUpdated];

    // Register APNs and Push kit
    [self registerForNotification];

    // Register for Applozic notification tap actions and network change notifications
    ALAppLocalNotifications *localNotification = [ALAppLocalNotifications appLocalNotificationHandler];
    [localNotification dataConnectionNotificationHandler];
    
    ALPushNotificationHandler *pushNotificationHandler = [ALPushNotificationHandler shared];
    [pushNotificationHandler dataConnectionNotificationHandler];

    // Override point for customization after application launch.
    NSLog(@"launchOptions: %@", launchOptions);
    if (launchOptions != nil) {
        NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary != nil) {
            NSLog(@"Launched from push notification: %@", dictionary);
            ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
            BOOL applozicProcessed = [pushNotificationService processPushNotification:dictionary updateUI:[NSNumber numberWithInt:APP_STATE_INACTIVE]];

            //IF not a appplozic notification, process it
            if (!applozicProcessed) {
                //Note: notification for app
            }
        }
    }

    return YES;
}

// Register APNs

-(void)registerForNotification
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
     {
        if(!error)
        {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [[UIApplication sharedApplication] registerForRemoteNotifications];  // required to get the app to do anything at all about push notifications
                NSLog(@"Push registration success." );
            });
        }
        else
        {
            NSLog(@"Push registration FAILED" );
            NSLog(@"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
            NSLog(@"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
        }
    }];
}

```

#### Sending an APNs device token to applozic server 

Add the below code in your Appdelegate file if any of these methods already exist then you can copy-paste the code from the below methods.

```Objc

// APNs device token sending to applozic

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)
deviceToken {

    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    NSString *apnDeviceToken = hexToken;
    NSLog(@"apnDeviceToken: %@", hexToken);

    if (![[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken]) {
        ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
        [registerUserClientService updateApnDeviceTokenWithCompletion
         :apnDeviceToken withCompletion:^(ALRegistrationResponse
                                          *rResponse, NSError *error) {

            if (error) {
                NSLog(@"%@",error);
                return;
            }
            NSLog(@"Registration response%@", rResponse);
        }];
    }
}

```
#### Receiving push notification

Once your app receives notification, pass it to the Applozic handler for chat notification processing.

```objc
// UNUserNotificationCenter delegates for chat
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification*)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"APNS willPresentNotification for userInfo: %@", userInfo);

    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];
        completionHandler(UNNotificationPresentationOptionNone);
        return;
    }
    completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse* )response withCompletionHandler:(nonnull void (^)(void))completionHandler {


    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService
                                                           alloc] init];
    NSDictionary *userInfo =  response.notification.request.content.userInfo;
    NSLog(@"APNS didReceiveNotificationResponse for userInfo: %@", userInfo);

    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:[UIApplication sharedApplication] withDictionary:userInfo];
        completionHandler();
        return;
    }
    completionHandler();
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{

    NSLog(@"RECEIVED_NOTIFICATION_WITH_COMPLETION :: %@", userInfo);
    ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
    if ([pushNotificationService isApplozicNotification:userInfo]) {
        [pushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    [[ALDBHandler sharedInstance] saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    NSLog(@"APP_ENTER_IN_FOREGROUND");
    [application setApplicationIconBadgeNumber:0];
}

```

### 4. Launch chat list

Implement the following code at the event or Button action designated for showing chat list screen.

```objc
ALChatManager * chatManager = [[ALChatManager alloc] init];
[chatManager launchChat:self];
```

### 5. Logout user

On logout of your app you need to logout the applozic user as well use the below method to logout the user:  

```objc
ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
[registerUserClientService logoutWithCompletionHandler:^(ALAPIResponse *response, NSError *error) {
    if(!error && [response.status isEqualToString:@"success"]) {
        NSLog(@"Logout success");
    } else {
        NSLog(@"Logout failed with response : %@",response.response);
    }
 }];
```

<a name="announcements"></a>
## Announcements :loudspeaker: 

All updates to this library are documented in our [releases](https://github.com/AppLozic/Applozic-Android-SDK/releases). For any queries, feel free to reach out us at github@applozic.com

<a name="roadmap"></a>
## Roadmap :vertical_traffic_light:

If you are interested in the future direction of this project, please take a look at our open [issues](https://github.com/AppLozic/Applozic-iOS-SDK/issues) and [pull requests](https://github.com/AppLozic/Applozic-iOS-SDK/pulls).<br> We would :heart: to hear your feedback.


<a name="feature"></a>
## Features :confetti_ball:

* One to one and Group Chat
* Image capture
* Photo sharing
* Location sharing
* Push notifications
* In App notifications
* Online presence
* Last seen at
* Unread message count
* Typing indicator
* Message sent
* Read Recipients and Delivery report
* Offline messaging
* User block/unblock
* Multi Device sync
* Application to user messaging
* Customized chat bubble
* UI Customization Toolkit
* Cross Platform Support(iOS,Android&Web)


<a name="about"></a>
## About & Help/Support :rainbow:

We provide support over at [StackOverflow](http://stackoverflow.com/questions/tagged/applozic) when you tag using applozic, ask us anything.

* Applozic is the best android chat sdk for instant messaging, still not convinced? 
    - Write to us at github@applozic.com 
    - We will be happy to schedule a demo for you.
    - Special plans for startup and open source contributors.

* Android Chat SDK https://github.com/AppLozic/Applozic-Android-SDK
* Web Chat Plugin https://github.com/AppLozic/Applozic-Web-Plugin
* iOS Chat SDK https://github.com/AppLozic/Applozic-iOS-SDK
* iOS Applozic Swfit SDK  https://github.com/AppLozic/ApplozicSwift
* Sample source code in Objective-C to build messenger and chat app link [here](https://www.applozic.com/blog/add-applozic-chat-framework-ios/)
* Sample Projects [https://github.com/AppLozic/Applozic-iOS-Chat-Samples](https://github.com/AppLozic/Applozic-iOS-Chat-Samples)

<a name="license"></a>
## License :heavy_check_mark:
This code library fully developed and supported by Applozic's [team of contributors](https://github.com/AppLozic/Applozic-iOS-SDK/graphs/contributors):sunglasses: and licensed under the [BSD-3 Clause License](https://github.com/AppLozic/Applozic-iOS-SDK/blob/master/LICENSE).
 
