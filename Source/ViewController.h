@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    UIView*   baseView;
    
    // the video camera session, device, etc.
    AVCaptureSession*           captureSession;
    AVCaptureDevice*            captureDevice;
    AVCaptureVideoPreviewLayer* previewLayer;
    AVCaptureVideoDataOutput*   videoDataOutput;
    dispatch_queue_t            videoDataOutputQueue;
    
    // camera control values
    CGFloat                     exposureGain;
    NSUInteger                  exposureDurationIndex;
    CGFloat                     whiteBalanceTemperature;
    CGFloat                     focusPosition;
    
    // camera controls
    UISlider*                   exposureDurationIndexSlider;
    UISlider*                   exposureGainSlider;
    UISlider*                   whiteBalanceTemperatureSlider;
    UISlider*                   focusPositionSlider;
}

@end
