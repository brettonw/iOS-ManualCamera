#import "ViewController.h"
#import "AppDelegate.h"
#import "AVCaptureDevicePrivate.h"

#define CLAMP(value, min, max)                                                  \
    value = (value > max) ?  max : value;                                       \
    value = (value < min) ? min : value

// these values are the denominator of the fractional time of the exposure, i.e.
// 1/1s, 1/2s, 1/3s, 1/4s... full and half stops
NSInteger exposureTimes[] = { 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024 };

@implementation ViewController

- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    // whatcha wanna do with the image?
}

- (void) configureCaptureDevice
{
    // set the interest point for the exposure
    NSError*    error = nil;
    if ([captureDevice lockForConfiguration:&error]) {

        // these two values seem to get set automatically by the system when the
        // capture device starts up. Unfortunately they seem to be set differently
        // depending on the lighting environment at start, so we rest them every
        // time to ensure consistency
        captureDevice.contrast = 0.0;
        captureDevice.saturation = 0.5;
        
        // we don't want the device to "help" us here, so we turn off low light
        // boost mode completely
        if (captureDevice.lowLightBoostSupported) {
            captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = NO;
        }
        
        // enable manual exposure mode, then check to see if that worked
        captureDevice.manualExposureSupportEnabled = YES;
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeManual]) {
            
            // set the gain and exposure duration, duration is set as a fractional
            // shutter speed just like a "real" camera. Gain is a value from 1..?
            // XXX Later I will map gain to an ISO value
            captureDevice.exposureGain = exposureGain;
            int     exposureDuration = exposureTimes[exposureDurationIndex];
            captureDevice.exposureDuration = AVCaptureExposureDurationMake(exposureDuration);
            
            // tap the device to use the new values by setting the mode to manual
            captureDevice.exposureMode = AVCaptureExposureModeManual;
        }

        // enable the manual focus mode, then check to see if that worked
        captureDevice.manualFocusSupportEnabled = YES;
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeManual]) {
            // set the focus position, the range is [0..1]
            CLAMP(focusPosition, 0, 1);
            captureDevice.focusPosition = focusPosition;
            
            // tap the device to use the new value by setting the mode to manual
            captureDevice.focusMode = AVCaptureFocusModeManual;
        }

        // note that there is no equivalent enabling pattern for manually
        // setting the white balance temperature, we can just set it directly
        // the range is [0..1], with 0.5 being a good first guess.
        // XXX Later I will try to map this to a degrees K temperature
        CLAMP(whiteBalanceTemperature, 0, 1);
        captureDevice.whiteBalanceTemperature = whiteBalanceTemperature;
        
        // tap the device to use the new value by setting the mode
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            captureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        }
        
        [captureDevice unlockForConfiguration];
    }
}

- (void) startVideo
{
    // activate the capture session
	NSError*    error = nil;
	
	captureSession = [AVCaptureSession new];
    [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
	
    // select a video device, make an input
	captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput*   deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
	if (error == nil) {
        if ([captureSession canAddInput:deviceInput]) {
            [captureSession addInput:deviceInput];
        }
        
        // make a video data output
        videoDataOutput = [AVCaptureVideoDataOutput new];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary*   rgbOutputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        videoDataOutput.videoSettings = rgbOutputSettings;
        videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        
        // create a serial dispatch queue used for the sample buffer delegate
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        videoDataOutputQueue = dispatch_queue_create ("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        
        if ([captureSession canAddOutput:videoDataOutput]) {
            [captureSession addOutput:videoDataOutput];
        }
        [videoDataOutput connectionWithMediaType:AVMediaTypeVideo].enabled = YES;
        
        previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
        previewLayer.backgroundColor = [UIColor blackColor].CGColor;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
        // make a rectangle that pushes the video to the "top" of the view so we
        // have room for controls under it
        CALayer*    rootLayer = [baseView layer];
        rootLayer.masksToBounds = YES;
        CGRect      bounds = rootLayer.bounds;
        CGRect      previewLayerBounds = CGRectMake(0, 0, bounds.size.width, floor(((bounds.size.width / 1280) * 720) + 0.5));
        previewLayer.frame = previewLayerBounds;
        [rootLayer addSublayer:previewLayer];
        
        [self configureCaptureDevice];
        [captureSession startRunning];
    }
}

- (void) stopVideo
{
    [captureSession stopRunning];
	[previewLayer removeFromSuperlayer];
}

- (void) handleSliderChanged:(id)sender
{
    exposureGain = exposureGainSlider.value;
    [self configureCaptureDevice];
}

- (void) loadView
{
    UIWindow*   window = APP_DELEGATE.window;
    CGRect      frame = window.frame;

    // this view automatically gets resized to fill the window
    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.backgroundColor = [UIColor redColor];
    
    // adjust the frame rect based on the orientation
    frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
    baseView = [[UIView alloc] initWithFrame:frame];
    baseView.backgroundColor = [UIColor blackColor];
    baseView.clipsToBounds = YES;
    [self.view addSubview:baseView];
    
    // set initial camera control parameters
    exposureGain = 1.0;
    exposureDurationIndex = 11;
    whiteBalanceTemperature = 0.5;
    focusPosition = 0.5;
    
    // put down a view to contain the controls
    UIView*     controlContainerView = [[UIView alloc] initWithFrame:frame];
    controlContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:controlContainerView];
    
    // put a slider down for exposure
    CGFloat     spacing = 20;
    CGFloat     doubleSpacing = spacing * 2;
    CGRect      sliderFrame = CGRectMake(spacing, spacing, frame.size.width - doubleSpacing, doubleSpacing);
    exposureGainSlider = [[UISlider alloc] initWithFrame:sliderFrame];
    exposureGainSlider.minimumValue = 1.0;
    exposureGainSlider.maximumValue = 10.0;
    exposureGainSlider.value = exposureGain;
    [exposureGainSlider addTarget:self action:@selector(handleSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [controlContainerView addSubview:exposureGainSlider];
    
    [self startVideo];
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
