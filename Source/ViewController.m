#import "ViewController.h"
#import "AppDelegate.h"

// these values are the denominator of the fractional time of the exposure, i.e.
// 1/1s, 1/2s, 1/3s, 1/4s... full and half stops
int exposureTimes[] = { 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096 };

@implementation ViewController

-(void) configureCamera:(id)sender
{
    // set the gain and exposure duration, duration is set as a fractional
    // shutter speed just like a "real" camera. Gain is a value from 0..1
    // which maps the minISO to maxISO range on the device
    float iso = exposureIsoSlider.value;
    int   exposureDuration = exposureTimes[(int)(exposureTimeIndexSlider.value + 0.5)];
    Time time = makeTime(1, exposureDuration);
    [camera commitExposureIso:iso andTime:time];
    
    // set the focus position, the range is [0..1], and report the focus control value
    camera.focus = focusPositionSlider.value;
}

-(void)cameraUpdatedBuffer:(id)sender {
    [self configureCamera:nil];
}

-(void)cameraUpdatedFocus:(id)sender {
    focusPositionLabel.text = [NSString stringWithFormat:@"%05.03f", camera.focus];
}

-(void)cameraUpdatedExposure:(id)sender {
    exposureIsoLabel.text = [NSString stringWithFormat:@"%05.03f", camera.iso];
    exposureTimeLabel.text = [NSString stringWithFormat:@"%d/%d sec", camera.time.count, camera.time.scale];
}

-(void)cameraSnaphotCompleted:(id)camera withSuccess:(BOOL)success {
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut
                     animations: ^{
                         feedbackView.alpha = 0.0;
                     }
                     completion: ^(BOOL finished){
                     }
     ];
}

-(void) handleTapGesture:(id)input {
}

-(void) handleSnapshotButton:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([camera snapshot]) {
            [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseIn
                             animations: ^{
                                 feedbackView.alpha = 0.95;
                             }
                             completion: ^(BOOL finished){
                             }
             ];
        }
    });
}

-(void) handleWhiteBalanceButton:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        PixelBuffer*    pixelBuffer = camera.buffer;
        
        // sample the target rect
        int             x = pixelBuffer.width * whiteBalancePoint.x;
        int             y = pixelBuffer.height * whiteBalancePoint.y;
        CGRect          sampleRect = CGRectMake(x - 5, y - 5, 11, 11);
        Color           sampleMeanColor = [pixelBuffer meanColorInRect:sampleRect];
        
        // and update the gains appropriately
        [camera setWhite:sampleMeanColor];
    });
}

// build a label
UILabel*    tmpLabel;
-(void) createLabelWithTitle:(NSString*)title atY:(CGFloat)y {
    CGRect      frame = controlContainerView.frame;
    CGFloat     spacing = 20;
    CGFloat     doubleSpacing = spacing * 2;
    CGFloat     halfWidth = frame.size.width / 2;
    CGRect      labelFrame = CGRectMake(halfWidth + spacing, y, halfWidth - doubleSpacing, spacing);

    // create the title  label
    tmpLabel = [[UILabel alloc] initWithFrame:labelFrame];
    tmpLabel.textAlignment = NSTextAlignmentLeft;
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.font = [UIFont systemFontOfSize:14.0];
    tmpLabel.text = title;
    [controlContainerView addSubview:tmpLabel];
    
    // create the value label
    tmpLabel = [[UILabel alloc] initWithFrame:labelFrame];
    tmpLabel.textAlignment = NSTextAlignmentRight;
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.font = [UIFont systemFontOfSize:14.0];
    tmpLabel.text = @"XXX";
    [controlContainerView addSubview:tmpLabel];
}

// build a slider and label together
UISlider*   tmpSlider;
-(void) createSliderWithTitle:(NSString*)title min:(CGFloat)min max:(CGFloat)max value:(CGFloat)value atY:(CGFloat)y
{
    [self createLabelWithTitle:title atY:y];
    
    CGRect      frame = controlContainerView.frame;
    CGFloat     spacing = 20;
    CGFloat     doubleSpacing = spacing * 2;
    CGFloat     halfWidth = frame.size.width / 2;
    
    // create the slider
    CGRect      sliderFrame = CGRectMake(halfWidth + spacing, CGRectGetMaxY(tmpLabel.frame), halfWidth - doubleSpacing, doubleSpacing);
    tmpSlider = [[UISlider alloc] initWithFrame:sliderFrame];
    tmpSlider.minimumValue = min;
    tmpSlider.maximumValue = max;
    tmpSlider.value = value;
    [tmpSlider addTarget:self action:@selector(configureCamera:) forControlEvents:UIControlEventValueChanged];
    [controlContainerView addSubview:tmpSlider];
}

-(void) loadView
{
    UIWindow*   window = APP_DELEGATE.window;
    CGRect      frame = window.frame;
    
    // this view automatically gets resized to fill the window
    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.backgroundColor = [UIColor redColor];
    
    // adjust the frame rect based on the orientation
    frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    baseView = [[UIView alloc] initWithFrame:frame];
    baseView.backgroundColor = [UIColor blackColor];
    baseView.clipsToBounds = YES;
    [self.view addSubview:baseView];
    
    // put down a view to contain the controls
    controlContainerView = [[UIView alloc] initWithFrame:frame];
    controlContainerView.backgroundColor = [UIColor clearColor];
    controlContainerView.userInteractionEnabled = YES;
    [controlContainerView addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)]];
    [self.view addSubview:controlContainerView];
    
    // setup the video feed
    camera = [[Camera alloc] initInView:baseView];
    camera.delegate = self;
    
    // put down the fStop
    [self createLabelWithTitle:@"fStop" atY:100];
    tmpLabel.text = [NSString stringWithFormat:@"%1.1f", camera.aperture];
    
    // put sliders down for camera controls
    FloatRange isoRange = camera.isoRange;
    [self createSliderWithTitle:@"ISO" min:isoRange.low max:isoRange.high value:interpolateFloatInRange(0.333, isoRange) atY:(CGRectGetMaxY(tmpLabel.frame) + 5)];
    exposureIsoSlider = tmpSlider; exposureIsoLabel = tmpLabel;
    
    [self createSliderWithTitle:@"Time" min:0 max:(ARRAY_SIZE(exposureTimes) - 1) value:6 atY:(CGRectGetMaxY(tmpSlider.frame) + 5)];
    exposureTimeIndexSlider = tmpSlider; exposureTimeLabel = tmpLabel;
    
    FloatRange focusRange = camera.focusRange;
    [self createSliderWithTitle:@"Focus" min:focusRange.low max:focusRange.high value:interpolateFloatInRange(0.5, focusRange) atY:(CGRectGetMaxY(tmpSlider.frame) + 10)];
    focusPositionSlider = tmpSlider; focusPositionLabel = tmpLabel;
    
    // add the button to take a snapshot
    snapshotButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    snapshotButton.frame = CGRectMake(frame.size.width - (20 + 60), 20, 60, 60);
    snapshotButton.backgroundColor = [UIColor blueColor];
    [snapshotButton layer].borderWidth = 3.0f;
    [snapshotButton layer].borderColor = [UIColor whiteColor].CGColor;
    [snapshotButton layer].cornerRadius = 24.0;
    [controlContainerView addSubview:snapshotButton];
    [snapshotButton addTarget:self action:@selector(handleSnapshotButton:) forControlEvents:UIControlEventTouchUpInside];
    [snapshotButton setTitle:@"O" forState:UIControlStateNormal];
    [snapshotButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // add the button to manage white balance
    whiteBalanceButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    whiteBalanceButton.frame = CGRectMake(frame.size.width - (2 * (20 + 60)), 20, 60, 60);
    whiteBalanceButton.backgroundColor = [UIColor blueColor];
    [whiteBalanceButton layer].borderWidth = 3.0f;
    [whiteBalanceButton layer].borderColor = [UIColor whiteColor].CGColor;
    [whiteBalanceButton layer].cornerRadius = 24.0;
    [controlContainerView addSubview:whiteBalanceButton];
    [whiteBalanceButton addTarget:self action:@selector(handleWhiteBalanceButton:) forControlEvents:UIControlEventTouchUpInside];
    [whiteBalanceButton setTitle:@"WB" forState:UIControlStateNormal];
    [whiteBalanceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // initialize the white balance
    whiteBalanceGains = camera.gains;
    whiteBalancePoint = CGPointMake(0.5, 0.5);
    CGRect previewBounds = camera.previewImageBounds;
    CGFloat x = previewBounds.origin.x + (previewBounds.size.width * whiteBalancePoint.x);
    CGFloat y = previewBounds.origin.y + (previewBounds.size.height * whiteBalancePoint.y);
    whiteBalanceFeedbackView = [[UIView alloc] initWithFrame:CGRectMake(x - 5, y - 5, 11, 11)];
    whiteBalanceFeedbackView.backgroundColor = [UIColor clearColor];
    whiteBalanceFeedbackView.layer.borderColor = [UIColor blueColor].CGColor;
    whiteBalanceFeedbackView.layer.borderWidth = 1;
    //whiteBalanceFeedbackView.hidden = NO;
    [controlContainerView addSubview:whiteBalanceFeedbackView];
    
    // setup the feedback view for flashing the screen when a picture takes
    feedbackView = [[UIView alloc] initWithFrame:frame];
    feedbackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    feedbackView.alpha = 0.0;
    feedbackView.userInteractionEnabled = YES;
    [self.view addSubview:feedbackView];

    // start the video feed
    [camera startVideo];
    [self configureCamera:nil];
}

-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
