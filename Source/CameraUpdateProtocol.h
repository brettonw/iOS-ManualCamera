@protocol CameraUpdateProtocol<NSObject>

/*
@required
-(void)requiredDelegateMethod;
*/

@optional
-(void)cameraUpdatedFocus:(id)camera;
-(void)cameraUpdatedExposure:(id)camera;
-(void)cameraUpdatedGains:(id)camera;
-(void)cameraUpdatedBuffer:(id)camera;
-(void)cameraSnaphotCompleted:(id)camera withSuccess:(BOOL)success;

@end
