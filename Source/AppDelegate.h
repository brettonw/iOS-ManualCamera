@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
+ (AppDelegate*) sharedAppDelegate;

@end

#define APP_DELEGATE    [AppDelegate sharedAppDelegate]
