#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void) loadView
{
    UIWindow*   window = APP_DELEGATE.window;
    CGRect      frame = window.frame;

    // this view automatically gets resized to fill the window, it seems
    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // adjust the frame rect
    frame = CGRectMake(0, 0, frame.size.width, frame.size.height);

    // decide how to frame the base view based on orientation
    CGRect      statusBarFrame = APPLICATION.statusBarFrame;
    CGFloat     statusBarHeight = MIN(statusBarFrame.size.width, statusBarFrame.size.height);
    CGFloat     baseViewFrameOriginY = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? statusBarHeight : 0;
    CGRect      baseViewFrame = CGRectMake(0, baseViewFrameOriginY, frame.size.width, frame.size.height - statusBarHeight);
    baseView = [[UIView alloc] initWithFrame:baseViewFrame];
    baseView.backgroundColor = [UIColor blackColor];
    baseView.clipsToBounds = YES;
    [self.view addSubview:baseView];
}
    
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
