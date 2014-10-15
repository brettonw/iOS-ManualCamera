iOS-ManualCamera
=======================

ManualCamera is an app to implement manual control of the camera functions on iOS 7 devices using private and undocumented APIs on the AVCaptureDevice.

*NOTE* This app does not work on iOS8 as the undocumented APIs it uses have changed. iOS8 supports manual camera controls using documented APIs, so I will not be updating this app to fix the issues.

While working on a project that uses the iPad camera to make scientific color measurements, we determined a need for APIs more suitable for our intended use. We need very precise control of the exposure and white balance for repeatable results within some error tolerance, and we need to work around a few things that are specific to Apple's intended use of the iPad and iPhone as simple point-and-shoot cameras. Thus was born an exploration of the world of Apple's private and undocumented APIs.

This work would not have been possible without the contributions of people posting on StackOverflow [about iOS private API documentation](http://stackoverflow.com/questions/1150360/ios-private-api-documentation/8063166#8063166), and the efforts of a few folks to share what they had figured out about the cameras. One of the most useful conversations is [Accessing iOS 6 new APIs for camera exposure and shutter speed](http://stackoverflow.com/questions/12635446/accessing-ios-6-new-apis-for-camera-exposure-and-shutter-speed/21443104#21443104). We cross-referenced multiple sources from all those conversations to build our own header with an Objective-C category on AVCaptureDevice so we could access the functions we needed.

ManualCamera demonstrates the use of Apple's private APIs to control:

* Exposure
* Gain
* WhiteBalance
* Focus
* Contrast
* Saturation

Please note that Apple reportedly will not approve any app for publication in their App Store if it uses private APIs. This work was done for a private application, and this documentation is supplied for others doing similar projects.
