#import "PixelBuffer.h"
#import "TimeRange.h"
#import "FloatRange.h"
#import "Gains.h"
#import "CameraUpdateProtocol.h"

@interface Camera : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate> {
    UIView*                     view;
    AVCaptureSession*           captureSession;
    AVCaptureDevice*            captureDevice;
    AVCaptureVideoPreviewLayer* previewLayer;
    AVCaptureVideoDataOutput*   videoDataOutput;
    dispatch_queue_t            videoDataOutputQueue;
    AVCaptureStillImageOutput*  stillImageOutput;
    
    PixelBuffer*    buffer;
    
    float           exposureIso;
    Time            exposureTime;
    BOOL            exposureDirty;
    
    BOOL            busy;
    BOOL            shouldCaptureBuffer;
}

#pragma mark -
#pragma mark Delegate
@property (nonatomic, weak) id<CameraUpdateProtocol> delegate;

#pragma mark -
#pragma mark Property Accessors
@property (readonly) BOOL busy;
@property (readonly, strong) PixelBuffer* buffer;

#pragma mark -
#pragma mark Exposure
@property float iso;
@property Time time;

-(void) commitExposure;
-(void) commitExposureIso:(float)iso andTime:(Time)time;
-(void) commitExposureIso:(float)iso;
-(void) commitExposureTime:(Time)time;

#pragma mark -
#pragma mark Color Balance
@property Gains gains;
-(void) setWhite:(Color)color;

#pragma mark -
#pragma mark Focus
@property float focus;

#pragma mark -
#pragma mark Ranges
@property (readonly) FloatRange isoRange;
@property (readonly) TimeRange timeRange;
@property (readonly) FloatRange focusRange;
@property (readonly) float aperture;

#pragma mark -
#pragma mark Start/Stop
-(void) startVideo;
-(void) stopVideo;
-(void) updateBuffer;
-(void) snapshot;

#pragma mark -
#pragma mark Constructor
-(id) initInView:(UIView*)inView;

@end
