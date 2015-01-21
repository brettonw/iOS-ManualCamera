#import "ViewController.h"
#import "AppDelegate.h"
#import "AVCaptureDevicePrivate.h"

// these values are the denominator of the fractional time of the exposure, i.e.
// 1/1s, 1/2s, 1/3s, 1/4s... full and half stops
NSInteger exposureTimes[] = { 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096 };

@implementation ViewController

- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    // whatcha wanna do with the image?
}

- (void) configureCaptureDevice:(id)sender
{
    // check to see if the sender is the commit timer
    if ((NSTimer*)sender == commitTimer) {
        commitTimer = nil;
    }
    if (commitTimer != nil) {
        // don't do anything, the timer will get it later
        return;
    }
    
    // set the interest point for the exposure
    NSError*    error = nil;
    if ([captureDevice lockForConfiguration:&error]) {
        // these two values seem to get set automatically by the system when the
        // capture device starts up. Unfortunately they seem to be set differently
        // depending on the lighting environment at start, so we reset them every
        // time to ensure consistency
        /*
        captureDevice.contrast = 0.0;
        captureDevice.saturation = 0.5;
         */
        
        // we don't want the device to "help" us here, so we turn off low light
        // boost mode completely
        if (captureDevice.lowLightBoostSupported) {
            captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = NO;
        }
        
        // set the gain and exposure duration, duration is set as a fractional
        // shutter speed just like a "real" camera. Gain is a value from 1..?
        captureDevice.exposureGain = exposureGainSlider.value;
        NSInteger   exposureDuration = exposureTimes[(NSUInteger)(exposureDurationIndexSlider.value + 0.5)];
        captureDevice.exposureDuration = CMTimeMake(1, (int32_t)exposureDuration);

        /*
        // enable the manual focus mode, then check to see if that worked
        captureDevice.manualFocusSupportEnabled = YES;
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeCustom]) {
            // set the focus position, the range is [0..1]
            captureDevice.focusPosition = focusPositionSlider.value;
            
            // tap the device to use the new value by setting the mode to manual
            captureDevice.focusMode = AVCaptureFocusModeCustom;

            // report the control values
            focusPositionLabel.text = [NSString stringWithFormat:@"%05.03f", captureDevice.focusPosition];
        }
         */

        /*
        // note that there is no equivalent enabling pattern for manually
        // setting the white balance temperature, we can just set it directly
        // the range is [0..1], with 0.5 being a good first guess.
        captureDevice.whiteBalanceTemperature = whiteBalanceTemperatureSlider.value;
        
        // tap the device to use the new value by setting the mode
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            captureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        }
         */
        
        // report the control values
        whiteBalanceTemperatureLabel.text = [NSString stringWithFormat:@"%05.03f", captureDevice.whiteBalanceTemperature];

        // try to commit the control values
        bool success = [captureDevice commit];
        [captureDevice unlockForConfiguration];
        if ( success) {
            // report the control values
            exposureGainLabel.text = [NSString stringWithFormat:@"%05.03f", captureDevice.exposureGain];
            exposureDurationLabel.text = [NSString stringWithFormat:@"%@%ld sec", (exposureDuration > 1) ? @"1 / " : @"", (long)exposureDuration];
        } else {
            if (commitTimer != nil) {
                [commitTimer invalidate];
            }
            // try again in just a moment - at least as long as a frame, with 5% buffer
            NSTimeInterval  interval = (1.0 / exposureDuration) * 1.05;
            commitTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(configureCaptureDevice:) userInfo:nil repeats:NO];
        }
    }
}

- (void) setupVideo
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
        
        // make a rectangle that pushes the video to the "top" of the view
        CGRect      previewLayerBounds = CGRectMake(0, 0, baseView.frame.size.width, floor(((baseView.frame.size.width / 1280) * 720) + 0.5));
        previewLayer.frame = previewLayerBounds;
        
        // set up the initial exposure and control values
        [self configureCaptureDevice:nil];
    }
}

- (void) startVideo
{
    [baseView.layer addSublayer:previewLayer];
    [captureSession startRunning];
}

- (void) stopVideo
{
    [captureSession stopRunning];
	[previewLayer removeFromSuperlayer];
}

// build a slider and label together
UILabel*    tmpLabel;
UISlider*   tmpSlider;
- (void) createSliderWithTitle:(NSString*)title min:(CGFloat)min max:(CGFloat)max value:(CGFloat)value atY:(CGFloat)y
{
    CGRect      frame = controlContainerView.frame;
    CGFloat     spacing = 20;
    CGFloat     doubleSpacing = spacing * 2;
    CGFloat     halfWidth = frame.size.width / 2;

    // create the title  label
    CGRect      labelFrame = CGRectMake(halfWidth + spacing, y, halfWidth - doubleSpacing, 20);
    tmpLabel = [[UILabel alloc] initWithFrame:labelFrame];
    tmpLabel.textAlignment = NSTextAlignmentLeft;
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.font = [UIFont systemFontOfSize:14.0];
    tmpLabel.text = title;
    [controlContainerView addSubview:tmpLabel];
    
    // create the value label
    tmpLabel = [[UILabel alloc] initWithFrame:labelFrame];
    tmpLabel.textAlignment = NSTextAlignmentRight;
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.font = [UIFont systemFontOfSize:14.0];
    tmpLabel.text = @"XXX";
    [controlContainerView addSubview:tmpLabel];
    
    // create the slider
    CGRect      sliderFrame = CGRectMake(halfWidth + spacing, CGRectGetMaxY(labelFrame), halfWidth - doubleSpacing, doubleSpacing);
    tmpSlider = [[UISlider alloc] initWithFrame:sliderFrame];
    tmpSlider.minimumValue = min;
    tmpSlider.maximumValue = max;
    tmpSlider.value = value;
    [tmpSlider addTarget:self action:@selector(configureCaptureDevice:) forControlEvents:UIControlEventValueChanged];
    [controlContainerView addSubview:tmpSlider];
}

- (void) loadView
{
    UIWindow*   window = APP_DELEGATE.window;
    CGRect      frame = window.frame;

    // this view automatically gets resized to fill the window
    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.backgroundColor = [UIColor redColor];
    
    // adjust the frame rect based on the orientation
    frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    baseView = [[UIView alloc] initWithFrame:frame];
    baseView.backgroundColor = [UIColor blackColor];
    baseView.clipsToBounds = YES;
    [self.view addSubview:baseView];
    
    // put down a view to contain the controls
    controlContainerView = [[UIView alloc] initWithFrame:frame];
    controlContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:controlContainerView];
    
    // put sliders down for camera controls
    [self createSliderWithTitle:@"Gain" min:0.0 max:1.0 value:0.333 atY:20];
    exposureGainSlider = tmpSlider; exposureGainLabel = tmpLabel;
    [self createSliderWithTitle:@"Duration" min:0 max:(ARRAY_SIZE(exposureTimes) - 1) value:6 atY:(CGRectGetMaxY(tmpSlider.frame) + 10)];
    exposureDurationIndexSlider = tmpSlider; exposureDurationLabel = tmpLabel;
    [self createSliderWithTitle:@"White Balance" min:0 max:1 value:0.5 atY:(CGRectGetMaxY(tmpSlider.frame) + 10)];
    whiteBalanceTemperatureSlider = tmpSlider; whiteBalanceTemperatureLabel = tmpLabel;
    [self createSliderWithTitle:@"Focus" min:0 max:1 value:0.5 atY:(CGRectGetMaxY(tmpSlider.frame) + 10)];
    focusPositionSlider = tmpSlider; focusPositionLabel = tmpLabel;
    
    // start the video feed
    commitTimer = nil;
    [self setupVideo];
    [self startVideo];
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
