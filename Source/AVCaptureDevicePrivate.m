#import "AVCaptureDevicePrivate.h"

@implementation AVCaptureDevice (AVCaptureDevicePrivate)

- (float)focusPosition
{
    return self.lensPosition;
}

- (void)setFocusPosition:(float)focusPosition
{
    [self setFocusModeLockedWithLensPosition:focusPosition completionHandler:nil];
}

- (BOOL)isManualFocusSupportEnabled
{
    return YES;
}

- (void)setManualFocusSupportEnabled:(BOOL)arg1
{
}

- (float)whiteBalanceTemperature
{
    return 0;
}

- (void)setWhiteBalanceTemperature:(float)arg1
{
}

static float    manualCameraExposureGain = 0.33f;
static float    manualCameraISO = 100.0f;
static CMTime   manualCameraExposureDuration = {1, 60, 1, 0};
static bool     manualCameraSynching = false;
static bool     manualCameraDirty = true;

- (float)exposureGain
{
    return manualCameraExposureGain;
}

- (void)setExposureGain:(float)exposureGain
{
    // check if the gain is different than the one we have
    if (exposureGain != manualCameraExposureGain) {
        // save the requested gain
        manualCameraDirty = true;
        manualCameraExposureGain = exposureGain;
        
        // compute the desired ISO when the input gain is in the range [0..1]
        NSLog(@"Gain = %f, minISO = %f, maxISO = %f", manualCameraExposureGain, self.activeFormat.minISO, self.activeFormat.maxISO);
        manualCameraISO = self.activeFormat.minISO + (manualCameraExposureGain * (self.activeFormat.maxISO - self.activeFormat.minISO));
    }
}

- (void)setExposureDuration:(CMTime)exposureDuration
{
    // validate the duration
    if (CMTIME_COMPARE_INLINE(exposureDuration, >=, self.activeFormat.minExposureDuration) AND
        CMTIME_COMPARE_INLINE(exposureDuration, <=, self.activeFormat.maxExposureDuration)) {
        // check if the duration is different than the one we have
        if (CMTIME_COMPARE_INLINE(exposureDuration, !=, manualCameraExposureDuration)) {
            // save the requested duration
            manualCameraDirty = true;
            manualCameraExposureDuration = exposureDuration;
        }
    }
}

-(bool)commit
{
    if (manualCameraDirty) {
        // check that we are not already synching
        if (NOT manualCameraSynching) {
            // flag that we are synching
            manualCameraSynching = true;
            
            // set the exposure
            self.exposureMode = AVCaptureExposureModeCustom;
            [self setExposureModeCustomWithDuration:manualCameraExposureDuration ISO:manualCameraISO completionHandler:^(CMTime syncTime) {
                NSLog(@"ISO = %f, exposure = %lld/%d sec", manualCameraISO, manualCameraExposureDuration.value, manualCameraExposureDuration.timescale);
                manualCameraSynching = false;
                manualCameraDirty = false;
            }];
            return true;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

@end
