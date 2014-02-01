iOS-ManualCameraControl
=======================

iOS-ManualCameraControl is an app to implement manual control of the camera functions on iOS devices using undocumented APIs on the AVCaptureDevice.

While working on a project that uses the iPad camera to make scientific color measurements, we determined Apple's public camera APIs are wholly unsuitable for our intended use. We need very precise control of the exposure and white balance for repeatable results within some error tolerance, and we need to work around a few things that are specific to Apple's intended use of the iPad and iPhone as simple point-and-shoot cameras. Thus was born an exploration of the world of Apple's private and undocumented APIs.

One thing that continues to be a source of conversation is the reason Apple keeps these APIs private. Most of their private libraries have implications for the user's privacy or impact battery life, but the functions we extracted don't seem to have those type of stigma associated with them. We can only speculate that Apple has entered into some sort of agreement with the imaging chip makers not to compete with higher functioning purpose-built cameras.

