### XCFramework for iPhone and iPhone simulator

This will guide you on generating XCFramework for the iPhone device and simulator follow the below steps one by one 

1. Select ``Applozic.xcodeproj`` and Click TARGET ``Applozic`` and go to Build settings search for ``Build libraries for Distribution`` and make it to ``YES``
2. Under Same TARGET ``Applozic`` go to Build settings search for ``Skip install`` and make it to ``NO``
3. Go to ``cd /Applozic-iOS-SDK/sample-with-framework`` in terminal
4. Archive build for iphone device use the below command in terminal 
 ```swift 
 xcodebuild archive -scheme Applozic -archivePath archives/ios -sdk iphoneos SKIP_INSTALL=NO
 ```
5. Archive build for iphone simulator below command in terminal 
  ```swift
 xcodebuild archive -scheme Applozic -archivePath archives/ios-sim -sdk iphonesimulator SKIP_INSTALL=NO 
 ```
6. Creating XCFramework 
 ```swift
 xcodebuild -create-xcframework \
 -framework archives/ios.xcarchive/Products/Library/Frameworks/Applozic.framework \
 -framework archives/ios-sim.xcarchive/Products/Library/Frameworks/Applozic.framework \
 -output Applozic.xcframework
 ```
7. The generated XCFramework will be under folder ``Applozic-iOS-SDK/sample-with-framework/Applozic.xcframework`` add ``Applozic.xcframework`` in your project.
