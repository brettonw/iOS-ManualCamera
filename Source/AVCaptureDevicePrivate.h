typedef struct {
    int64_t     a;
    int32_t     denom;
    uint32_t    c;
    int64_t     d;
} AVCaptureExposureDurationStruct;

static inline AVCaptureExposureDurationStruct
AVCaptureExposureDurationMake(int32_t denom) {
    AVCaptureExposureDurationStruct ed;
    ed.a = 1; ed.denom = denom; ed.c = 1; ed.d = 0;
    return ed;
}


@interface AVCaptureDevice (AVCaptureDevicePrivate)

@property(nonatomic) float whiteBalanceTemperature;

#define AVCaptureFocusModeManual        3
@property(nonatomic, getter=isManualFocusSupportEnabled) BOOL manualFocusSupportEnabled;
@property(nonatomic) float focusPosition;

#define AVCaptureExposureModeManual     3
@property(nonatomic, getter=isManualExposureSupportEnabled) BOOL manualExposureSupportEnabled;
@property(nonatomic) float exposureGain;
@property(nonatomic) AVCaptureExposureDurationStruct exposureDuration;

@property(nonatomic) float saturation;
@property(nonatomic) float contrast;

@end
