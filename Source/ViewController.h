@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    UIView*                     baseView;
    UIView*                     controlContainerView;
    
    // the video camera session, device, etc.
    AVCaptureSession*           captureSession;
    AVCaptureDevice*            captureDevice;
    AVCaptureVideoPreviewLayer* previewLayer;
    AVCaptureVideoDataOutput*   videoDataOutput;
    dispatch_queue_t            videoDataOutputQueue;
    
    // sliders to manipulate the camera control values
    UISlider*                   exposureDurationIndexSlider;
    UISlider*                   exposureGainSlider;
    UISlider*                   focusPositionSlider;
    
    // labels to show the camera control values
    UILabel*                    exposureDurationLabel;
    UILabel*                    exposureGainLabel;
    UILabel*                    focusPositionLabel;
    
    // timer to commit the settings
    NSTimer*                    commitTimer;
}

@end
