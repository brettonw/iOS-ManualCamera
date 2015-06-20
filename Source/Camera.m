#import "Camera.h"
#import "FloatMath.h"
#import <Photos/Photos.h>

@implementation Camera

#pragma mark -
#pragma mark Delegate
@synthesize delegate;

#pragma mark -
#pragma mark Property Accessors
@synthesize busy = busy;
@synthesize buffer = buffer;

#pragma mark -
#pragma mark Exposure
@dynamic iso;

-(float) iso {
    return exposureIso;
}

-(void) setIso:(float)iso {
    if (NOT floatsAreEquivalent(iso, exposureIso)) {
        exposureIso = iso;
        exposureDirty = YES;
        NSLog(@"Set ISO %0.02f", iso);
    }
}

@dynamic time;

-(Time) time {
    return exposureTime;
}

-(void) setTime:(Time)time {
    if (NOT timesAreEquivalent(time, exposureTime)) {
        exposureTime = time;
        exposureDirty = YES;
        NSLog(@"Set time %d/%d sec", time.count, time.scale);
    }
}

-(void) commitExposure {
    // don't do this unless the exposure values have changed
    if (exposureDirty) {
        // lock the device for configuration
        NSError*    error = nil;
        if (NOT busy) {
            if ([captureDevice lockForConfiguration:&error]) {
                busy = YES;
                // objective C documentation recommends against strongly capturing self...
                Camera* __weak weakSelf = self;
                NSLog(@"Commit exposure");
                CMTime  cmtime = CMTimeMake(exposureTime.count, exposureTime.scale);
                [captureDevice setExposureModeCustomWithDuration:cmtime ISO:exposureIso completionHandler:^(CMTime syncTime) {
                    //NSLog(@"- SUCCESS");
                    busy = NO;
                    exposureDirty = NO;
                    shouldCaptureBuffer = YES;
                    if (delegate && [delegate respondsToSelector:@selector(cameraUpdatedExposure:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.delegate cameraUpdatedExposure:weakSelf];
                        });
                    }
                }];
                [captureDevice unlockForConfiguration];
            } else {
                NSLog(@"Unable to lock device for exposure");
            }
        } else {
            //NSLog(@"Unable to commit exposure: BUSY");
        }
    }
}

-(void) commitExposureIso:(float)iso andTime:(Time)time {
    [self setIso:iso];
    [self setTime:time];
    [self commitExposure];
}

-(void) commitExposureIso:(float)iso {
    [self setIso:iso];
    [self commitExposure];
}

-(void) commitExposureTime:(Time)time {
    [self setTime:time];
    [self commitExposure];
}

#pragma mark -
#pragma mark Color Balance
@dynamic gains;

-(Gains) gains {
    AVCaptureWhiteBalanceGains deviceGains = captureDevice.deviceWhiteBalanceGains;
    return makeGains(deviceGains.redGain, deviceGains.greenGain, deviceGains.blueGain, captureDevice.maxWhiteBalanceGain);
}

-(void) setGains:(Gains)gains {
    if (NOT gainsAreEquivalent([self gains], gains)) {
        // lock the device for configuration
        NSError*    error = nil;
        if (NOT busy) {
            if ([captureDevice lockForConfiguration:&error]) {
                busy = YES;
                // objective C documentation recommends against strongly capturing self...
                Camera* __weak weakSelf = self;
                NSLog(@"Commit gains");
                [captureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:*(AVCaptureWhiteBalanceGains*)&gains completionHandler:^(CMTime syncTime) {
                    busy = NO;
                    //NSLog(@"- SUCCESS");
                    shouldCaptureBuffer = YES;
                    if (delegate && [delegate respondsToSelector:@selector(cameraUpdatedGains:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.delegate cameraUpdatedGains:weakSelf];
                        });
                    }
                }];
                [captureDevice unlockForConfiguration];
            } else {
                NSLog(@"Unable to lock device for gains");
            }
        } else {
            //NSLog(@"Unable to commit gains: BUSY");
        }
    }
}

-(void) setWhite:(Color)color {
    Gains whiteGains = makeGainsWhite([self gains], color.red, color.green, color.blue, captureDevice.maxWhiteBalanceGain);
    [self setGains:whiteGains];
}

#pragma mark -
#pragma mark Focus
@dynamic focus;

-(float) focus {
    return captureDevice.lensPosition;
}

-(void) setFocus:(float)focus {
    if (NOT floatsAreEquivalentEpsilon(focus, captureDevice.lensPosition, 4.0e-3)) {
        // lock the device for configuration
        NSError*    error = nil;
        if (NOT busy) {
            if ([captureDevice lockForConfiguration:&error]) {
                busy = YES;
                // objective C documentation recommends against strongly capturing self...
                Camera* __weak weakSelf = self;
                NSLog(@"Commit focus %0.02f", focus);
                [captureDevice setFocusModeLockedWithLensPosition:focus completionHandler:^(CMTime syncTime) {
                    busy = NO;
                    //NSLog(@"- SUCCESS");
                    shouldCaptureBuffer = YES;
                    if (delegate && [delegate respondsToSelector:@selector(cameraUpdatedFocus:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.delegate cameraUpdatedFocus:weakSelf];
                        });
                    }
                }];
                [captureDevice unlockForConfiguration];
            } else {
                NSLog(@"Unable to lock device for focus");
            }
        } else {
            //NSLog(@"Unable to commit focus: BUSY");
        }
    }
}

#pragma mark -
#pragma mark Ranges
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

@dynamic imageSize;

- (CMVideoDimensions) imageSize {
    CMFormatDescriptionRef formatDescription = captureDevice.activeFormat.formatDescription;
    return CMVideoFormatDescriptionGetDimensions(formatDescription);
}

@synthesize previewImageBounds = previewLayerBounds;


#pragma mark -
#pragma mark Start/Stop
-(void) startVideo {
    [view.layer addSublayer:previewLayer];
    [captureSession startRunning];
}

-(void) stopVideo {
    [captureSession stopRunning];
    [previewLayer removeFromSuperlayer];
}

-(void) updateBuffer {
    if (NOT busy) {
        shouldCaptureBuffer = YES;
    }
}

-(AVCaptureConnection*) getCaptureConnection {
#if 1
    return [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
#else
    for (AVCaptureConnection* connection in stillImageOutput.connections) {
        for (AVCaptureInputPort* port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                return connection;
            }
        }
    }
    return nil;
#endif
}

-(BOOL) snapshot {
    AVCaptureConnection* connection = [self getCaptureConnection];
    if (connection != nil) {
        if (NOT busy) {
            busy = YES;
            // objective C documentation recommends against strongly capturing self...
            Camera* __weak weakSelf = self;
            NSLog(@"Commit Image Capture");
            [stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError* error) {
                busy = NO;
                //NSLog(@"- SUCCESS");
                if (error == nil) {
                    // the sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                    NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                    UIImage* image = [UIImage imageWithData:imageData];
                    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                        if (status == PHAuthorizationStatusAuthorized) {
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                            } completionHandler:^(BOOL success, NSError* error) {
                                NSLog(@"Snapshot completed with success: %@", success ? @"YES" : @"NO");
                                shouldCaptureBuffer = YES;
                                if (delegate && [delegate respondsToSelector:@selector(cameraSnaphotCompleted:withSuccess:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [weakSelf.delegate cameraSnaphotCompleted:weakSelf withSuccess:success];
                                    });
                                }
                            }];
                        }
                    }];
                }
                else {
                    NSLog(@"Could not capture still image: %@", error);
                }
            }];
            return YES;
        } else {
            //NSLog(@"Unable to commit image capture: BUSY");
        }
    } else {
        NSLog(@"Could not find connection");
    }
    return NO;
}

#pragma mark -
#pragma mark Constructor
-(void) setupVideoCapture:(UIView*)inView {
    // activate the capture session
    
    captureSession = [AVCaptureSession new];
    //[captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    [captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // select a video device (probably the back camera), make an input
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError* error = nil;
    AVCaptureDeviceInput* deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
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
        
        // create a still capture output
        stillImageOutput = [AVCaptureStillImageOutput new];
        stillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
        stillImageOutput.highResolutionStillImageOutputEnabled = YES;
        if ([captureSession canAddOutput:stillImageOutput]) {
            [captureSession addOutput:stillImageOutput];
        }
        [stillImageOutput connectionWithMediaType:AVMediaTypeVideo].enabled = YES;
        
        // create the preview image capability
        previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
        previewLayer.backgroundColor = [UIColor blackColor].CGColor;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
        // make a rectangle that pushes the video to the "top" of the view
        view = inView;
        CMVideoDimensions   imageDimensions = self.imageSize;
        CGSize imageSize = CGSizeMake(imageDimensions.width, imageDimensions.height);
        CGSize viewSize = view.frame.size;
        
        // scale this differently
        CGFloat imageAspect = imageSize.width / imageSize.height;
        CGFloat viewAspect = viewSize.width / viewSize.height;
        previewLayerBounds = (imageAspect > viewAspect) ?
            CGRectMake(0, 0, viewSize.width, viewSize.width / imageAspect) :
            CGRectMake(0, 0, viewSize.height * imageAspect, viewSize.height);
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

#pragma mark -
#pragma mark Sample Buffer Delegate
- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    if (shouldCaptureBuffer) {
        buffer = [[PixelBuffer alloc] initWithCVPixelBufferRef:CMSampleBufferGetImageBuffer (sampleBuffer)];
        shouldCaptureBuffer = NO;
        if (delegate && [delegate respondsToSelector:@selector(cameraUpdatedBuffer:)]) {
            [delegate cameraUpdatedBuffer:self];
            // objective C documentation recommends against strongly capturing self...
            Camera* __weak weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate cameraUpdatedBuffer:weakSelf];
            });
        }
    }
}

@end
