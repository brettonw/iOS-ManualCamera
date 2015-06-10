@protocol CameraUpdateProtocol;
@protocol CameraUpdateProtocol<NSObject>

/*
@required
-(void)requiredDelegateMethod;
*/

@optional
-(void)focusUpdated:(id)camera;
-(void)exposureUpdated:(id)camera;
-(void)gainsUpdated:(id)camera;

@end
