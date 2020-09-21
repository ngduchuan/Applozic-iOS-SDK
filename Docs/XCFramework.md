To add the Applozic framework manually, a .xcframework file is required. Follow these steps to create an Applozic.xcframework file

1. Go to Applozic sample folder in the terminal:
``cd /path/to/Applozic/Applozic-iOS-SDK/sample-with-framework``
2. Archive the framework for each platform. Run these two commands to archive for the iOS device and Simulator:
 
    **NOTE**: For release, it will be: ``-configuration Release`` in below command.
 
 ```swift 
 # For iOS Device
 xcodebuild archive -scheme Applozic -archivePath archives/ios -sdk iphoneos SKIP_INSTALL=NO
 
 # For Simulator
 xcodebuild archive -scheme Applozic -archivePath archives/ios-sim -sdk iphonesimulator SKIP_INSTALL=NO 
 ```
3. For creating XCFramework. Run the below command:
 ```swift
 xcodebuild -create-xcframework \
 -framework archives/ios.xcarchive/Products/Library/Frameworks/Applozic.framework \
 -framework archives/ios-sim.xcarchive/Products/Library/Frameworks/Applozic.framework \
 -output Applozic.xcframework
 ```
4. The generated XCFramework can now be copied from: `Applozic-iOS-SDK/sample-with-framework/Applozic.xcframework`` add ``Applozic.xcframework`` in your project.
