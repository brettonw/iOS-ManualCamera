#import "Camera.h"

@interface ViewController : UIViewController <CameraUpdateProtocol> {
    UIView*                     baseView;
    UIView*                     controlContainerView;
    Camera*                     camera;
    
    // sliders to manipulate the camera control values
    UISlider*                   exposureTimeIndexSlider;
    UISlider*                   exposureIsoSlider;
    UISlider*                   focusPositionSlider;
    
    // labels to show the camera control values
    UILabel*                    exposureTimeLabel;
    UILabel*                    exposureIsoLabel;
    UILabel*                    focusPositionLabel;
    
    // configurations
    Gains                       whiteBalanceGains;
    
    // white balance considerations
    CGPoint                     whiteBalancePoint;
    UIView*                     whiteBalanceFeedbackView;
}

@end
