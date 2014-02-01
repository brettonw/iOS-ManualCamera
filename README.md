iOS-ManualCamera
=======================

ManualCamera is an app to implement manual control of the camera functions on iOS devices using private and undocumented APIs on the AVCaptureDevice.

While working on a project that uses the iPad camera to make scientific color measurements, we determined Apple's public camera APIs are wholly unsuitable for our intended use. We need very precise control of the exposure and white balance for repeatable results within some error tolerance, and we need to work around a few things that are specific to Apple's intended use of the iPad and iPhone as simple point-and-shoot cameras. Thus was born an exploration of the world of Apple's private and undocumented APIs.

One thing that continues to be a source of conversation is the reason Apple keeps these APIs private. Most of their private libraries have implications for the user's privacy or impact battery life, but the functions we extracted don't seem to have those type of stigma associated with them. We can only speculate that Apple has entered into some sort of agreement with the imaging chip makers not to compete with higher functioning purpose-built cameras.

This work would not have been possible without the contributions of people posting on StackOverflow [about iOS private API documentation](http://stackoverflow.com/questions/1150360/ios-private-api-documentation/8063166#8063166), and the efforts of a few folks to share what they had figured out about the cameras. One of the most useful conversations is [Accessing iOS 6 new APIs for camera exposure and shutter speed](http://stackoverflow.com/questions/12635446/accessing-ios-6-new-apis-for-camera-exposure-and-shutter-speed/21443104#21443104). We cross-referenced multiple sources from all those conversations to build our own AVCaptureDevicePrivate.h header with an Objective-C category, so we could access the functions we needed, and that is included in this project.

* Exposure
* Gain
* WhiteBalance
* Focus
* Contrast
* Saturation

Special note about low light boost mode: Apple made the decision to have this mode enable automatically if the lighting conditions demand it.
