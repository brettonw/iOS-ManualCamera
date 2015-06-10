#import "PixelBuffer.h"
//#import "Vector3.h"

@implementation PixelBuffer

- (id) initWithCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    if (self = [super init])
    {
        m_pixelBufferRef = CVPixelBufferRetain (pixelBufferRef);
        if (CVPixelBufferLockBaseAddress (m_pixelBufferRef, 0) == kCVReturnSuccess) {
            m_bytesPerRow = CVPixelBufferGetBytesPerRow (m_pixelBufferRef);
            m_pixelData = CVPixelBufferGetBaseAddress (m_pixelBufferRef);
        } else {
            NSLog(@"initWithCVPixelBufferRef FAILED");
        }
    }
    return self;
}

- (void) dealloc
{
    [self finished];
}

- (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image
{
    CGSize              frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary*       options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef    pixelBufferRef = nil;
    CVReturn            status = CVPixelBufferCreate (kCFAllocatorDefault, frameSize.width, frameSize.height,  kCMPixelFormat_32BGRA, (__bridge CFDictionaryRef) options, &pixelBufferRef);
    if ((status == kCVReturnSuccess) AND (pixelBufferRef != nil)) {
        CVPixelBufferLockBaseAddress (pixelBufferRef, 0);
        void*               pixelData = CVPixelBufferGetBaseAddress (pixelBufferRef);
        size_t              bytesPerRow = CVPixelBufferGetBytesPerRow (pixelBufferRef);
        CGColorSpaceRef     rgbColorSpace = CGColorSpaceCreateDeviceRGB ();
        CGContextRef        context = CGBitmapContextCreate (pixelData, frameSize.width, frameSize.height, 8, bytesPerRow, rgbColorSpace, (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
        
        CGContextDrawImage (context, CGRectMake (0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
        CGColorSpaceRelease (rgbColorSpace);
        CGContextRelease (context);
        
        CVPixelBufferUnlockBaseAddress (pixelBufferRef, 0);
    }
    return pixelBufferRef;
}

- (void) finished
{
    if (m_pixelBufferRef) {
        CVPixelBufferUnlockBaseAddress (m_pixelBufferRef, 0);
        CVPixelBufferRelease (m_pixelBufferRef);
        m_pixelBufferRef = nil;
    }
}

- (Pixel*) pixelsAtX:(int)x Y:(int)y
{
    return (Pixel*)(m_pixelData + (y * m_bytesPerRow) + (x * sizeof(Pixel)));
}

- (Pixel) pixelAtX:(int)x Y:(int)y
{
    if ((x >= 0) AND (y >= 0) AND (x < self.width) AND (y < self.height)) {
    return *[self pixelsAtX:x Y:y];
    }
    static UInt32  white = 0xffffffff;
    return *(Pixel*)(&white);
}

- (CGRect)  trimRect:(CGRect)rectIn
{
    CGFloat left0 = MAX (rectIn.origin.x, 0);
    CGFloat left = MIN (left0, self.width - 1);
    CGFloat top0 = MAX (rectIn.origin.y, 0);
    CGFloat top  = MIN (top0, self.height - 1);
    CGFloat width = MIN (rectIn.size.width, self.width - left);
    CGFloat height = MIN (rectIn.size.height, self.height - top);
    return CGRectMake(left, top, width, height);
}

- (void) computeMeanColorInRect:(CGRect)rect output:(double*)colorAccumulator
{
    colorAccumulator[0] = 0; colorAccumulator[1] = 0; colorAccumulator[2] = 0;
    Pixel*      pixels = [self pixelsAtX:rect.origin.x Y:rect.origin.y];
    
    // loop over the pixels within the specified rectangle to compute the mean
    for (int y = 0; y < rect.size.height; ++y) {
        for (int x = 0; x < rect.size.width; ++x) {
            Pixel   pixel = pixels[x];
            colorAccumulator[0] += pixel.r; colorAccumulator[1] += pixel.g; colorAccumulator[2] += pixel.b;
        }
        pixels += self.stride;
    }
    double      count = rect.size.width * rect.size.height;
    colorAccumulator[0] /= count; colorAccumulator[1] /= count; colorAccumulator[2] /= count;
}

- (Color) meanColorInRect:(CGRect)rectIn
{
    // make sure we stay in bounds
    CGRect      rect = [self trimRect:rectIn];
    
    double      colorAccumulator[3];
    [self computeMeanColorInRect:rect output:colorAccumulator];
    return makeColor(colorAccumulator[0] / 255.0f, colorAccumulator[1] / 255.0f, colorAccumulator[2] / 255.0f);
}

@dynamic width;
@dynamic height;
@dynamic stride;

- (size_t) width
{
    return CVPixelBufferGetWidth (m_pixelBufferRef);
}

- (size_t) height
{
    return CVPixelBufferGetHeight (m_pixelBufferRef);
}

- (size_t) stride
{
    return m_bytesPerRow / sizeof(Pixel);
}

@end
