#import "Camera.h"

@implementation Camera

@synthesize buffer = buffer;
@synthesize delegate;
@synthesize busy = busy;

@dynamic iso;

-(float) iso {
    return exposureIso;
}

-(void) setIso:(float)iso {
    exposureIso = iso;
    exposureDirty = YES;
}

@dynamic time;

-(Time) time {
    return exposureTime;
}

-(void) setTime:(Time)time {
    exposureTime = time;
    exposureDirty = YES;
}

@dynamic gains;

-(Gains) gains {
    AVCaptureWhiteBalanceGains deviceGains = captureDevice.deviceWhiteBalanceGains;
    return makeGains(deviceGains.redGain, deviceGains.greenGain, deviceGains.blueGain, captureDevice.maxWhiteBalanceGain);
}

-(void) setGains:(Gains)gains {
    // lock the device for configuration
    NSError*    error = nil;
    if ([captureDevice lockForConfiguration:&error]) {
        // objective C documentation recommends against strongly capturing self...
        Camera* __weak weakSelf = self;
        busy = YES;
        [captureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:*(AVCaptureWhiteBalanceGains*)&gains completionHandler:^(CMTime syncTime) {
            busy = NO;
            shouldCaptureBuffer = YES;
            if (delegate && [delegate respondsToSelector:@selector(gainsUpdated:)]) {
                [weakSelf.delegate gainsUpdated:weakSelf];
            }
        }];
        [captureDevice unlockForConfiguration];
    }
}

@dynamic focus;

-(float) focus {
    return captureDevice.lensPosition;
}

-(void) setFocus:(float)focus {
    // lock the device for configuration
    NSError*    error = nil;
    if ([captureDevice lockForConfiguration:&error]) {
        // objective C documentation recommends against strongly capturing self...
        Camera* __weak weakSelf = self;
        busy = YES;
        [captureDevice setFocusModeLockedWithLensPosition:focus completionHandler:^(CMTime syncTime) {
            busy = NO;
            shouldCaptureBuffer = YES;
            if (delegate && [delegate respondsToSelector:@selector(focusUpdated:)]) {
                [weakSelf.delegate focusUpdated:weakSelf];
            }
        }];
        [captureDevice unlockForConfiguration];
    }
}

-(void) commitExposure {
    // don't do this unless the exposure values have changed
    if (exposureDirty) {
        // lock the device for configuration
        NSError*    error = nil;
        if ([captureDevice lockForConfiguration:&error]) {
            // objective C documentation recommends against strongly capturing self...
            Camera* __weak weakSelf = self;
            busy = YES;
            CMTime  cmtime = CMTimeMake(exposureTime.count, exposureTime.scale);
            [captureDevice setExposureModeCustomWithDuration:cmtime ISO:exposureIso completionHandler:^(CMTime syncTime) {
                exposureDirty = NO;
                busy = NO;
                shouldCaptureBuffer = YES;
                if (delegate && [delegate respondsToSelector:@selector(exposureUpdated:)]) {
                    [weakSelf.delegate exposureUpdated:weakSelf];
                }
            }];
            [captureDevice unlockForConfiguration];
        }
    }
}

-(void) setExposureIso:(float)iso andTime:(Time)time {
    exposureIso = iso;
    exposureTime = time;
    exposureDirty = YES;
    [self commitExposure];
}

-(void) setExposureIso:(float)iso {
    exposureIso = iso;
    exposureDirty = YES;
    [self commitExposure];
}

-(void) setExposureTime:(Time)time {
    exposureTime = time;
    exposureDirty = YES;
    [self commitExposure];
}

@dynamic isoRange;

-(FloatRange) isoRange {
    return makeFloatRange(captureDevice.activeFormat.minISO, captureDevice.activeFormat.maxISO);
}

@dynamic timeRange;

-(TimeRange) timeRange {
    // would like to base this on the actuals at some point
    return makeTimeRange(makeTime(1, 2048), makeTime(2, 1));
}

@dynamic focusRange;

-(FloatRange) focusRange {
    return makeFloatRange(0.0, 1.0);
}

@dynamic aperture;

-(float) aperture {
    return captureDevice.lensAperture;
}

-(void) startVideo {
    [view.layer addSublayer:previewLayer];
    [captureSession startRunning];
}

-(void) stopVideo {
    [captureSession stopRunning];
    [previewLayer removeFromSuperlayer];
}

-(void) setupVideoCapture:(UIView*)inView {
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
        view = inView;
        CGRect      previewLayerBounds = CGRectMake(0, 0, view.frame.size.width, floor(((view.frame.size.width / 1280) * 720) + 0.5));
        previewLayer.frame = previewLayerBounds;
    }
}

-(id) initInView:(UIView*)inView {
    if ((self = [super init]) != nil) {
        // some basic initialization
        busy = NO;
        exposureDirty = NO;
        shouldCaptureBuffer = NO;

        // set up the camera
        [self setupVideoCapture:inView];
        
        // configure a starting state
    }
    return self;
}


- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    if (shouldCaptureBuffer) {
        buffer = [[PixelBuffer alloc] initWithCVPixelBufferRef:CMSampleBufferGetImageBuffer (sampleBuffer)];
        shouldCaptureBuffer = NO;
    }
}

@end
