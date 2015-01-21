@interface AVCaptureDevice (AVCaptureDevicePrivate)

@property(nonatomic) float whiteBalanceTemperature;
@property(nonatomic, getter=isManualFocusSupportEnabled) BOOL manualFocusSupportEnabled;
@property(nonatomic) float focusPosition;

#define AVCaptureExposureModeCustom     3
@property(nonatomic, getter=isManualExposureSupportEnabled) BOOL manualExposureSupportEnabled;
@property(nonatomic) float exposureGain;
@property(nonatomic) CMTime exposureDuration;

@property(nonatomic) float saturation;
@property(nonatomic) float contrast;

-(bool)commit;

@end
