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
    
    PixelBuffer*    buffer;
    
    float           exposureIso;
    Time            exposureTime;
    BOOL            exposureDirty;
    
    BOOL            busy;
    BOOL            shouldCaptureBuffer;
}

@property (nonatomic, weak) id<CameraUpdateProtocol> delegate;

@property (readonly) BOOL busy;

@property float iso;
@property Time time;

-(void) commitExposure;
-(void) setExposureIso:(float)iso andTime:(Time)time;
-(void) setExposureIso:(float)iso;
-(void) setExposureTime:(Time)time;

@property Gains gains;
-(void) setWhite:(Color)color;

@property float focus;

@property (readonly) FloatRange isoRange;
@property (readonly) TimeRange timeRange;
@property (readonly) FloatRange focusRange;
@property (readonly) float aperture;

@property (readonly, strong) PixelBuffer* buffer;

-(void) startVideo;
-(void) stopVideo;
-(void) updateBuffer;

-(id) initInView:(UIView*)inView;

@end
