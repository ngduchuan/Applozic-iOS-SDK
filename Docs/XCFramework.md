To integrate the Applozic framework manually, a .xcframework file is required. Follow these steps to create an ApplozicCore.xcframework and Applozic.xcframework file

Applozic.xcframework requires the ApplozicCore.xcframework to run in your project

1. Go to Applozic sample folder in the terminal:
``cd /path/to/Applozic/Applozic-iOS-SDK/sample-with-framework``
2. Archive the framework for each platform. Run these command one by one to archive for the iOS device and Simulator:
 
    **NOTE**: For release, it will be: ``-configuration Release`` in below command.
    
Archive the framework for ApplozicCore :

 ```swift 
 # For iOS Device
 xcodebuild archive -scheme ApplozicCore -archivePath archives-core/ios -sdk iphoneos SKIP_INSTALL=NO
 
 # For Simulator
 xcodebuild archive -scheme ApplozicCore -archivePath archives-core/ios-sim -sdk iphonesimulator SKIP_INSTALL=NO 
 ```

 Archive the framework for Applozic :

```swift 
# For iOS Device
xcodebuild archive -scheme Applozic -archivePath archives/ios -sdk iphoneos SKIP_INSTALL=NO

# For Simulator
xcodebuild archive -scheme Applozic -archivePath archives/ios-sim -sdk iphonesimulator SKIP_INSTALL=NO 
```
 
3. For creating XCFramework's. Run the below command:

  ApplozicCore.xcframework :

 ```swift
 xcodebuild -create-xcframework \
 -framework archives-core/ios.xcarchive/Products/Library/Frameworks/ApplozicCore.framework \
 -framework archives-core/ios-sim.xcarchive/Products/Library/Frameworks/ApplozicCore.framework \
 -output ApplozicCore.xcframework
 ```
 Applozic.xcframework :

```swift
xcodebuild -create-xcframework \
-framework archives/ios.xcarchive/Products/Library/Frameworks/Applozic.framework \
-framework archives/ios-sim.xcarchive/Products/Library/Frameworks/Applozic.framework \
-output Applozic.xcframework
```
 
4. The generated XCFramework's ApplozicCore and Applozic can now be copied from: `Applozic-iOS-SDK/sample-with-framework/` add `ApplozicCore.xcframework` and `Applozic.xcframework` in your project.
