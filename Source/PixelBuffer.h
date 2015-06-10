#import "Pixel.h"
#import "Color.h"

@interface PixelBuffer : NSObject {
    CVPixelBufferRef    m_pixelBufferRef;
    size_t              m_bytesPerRow;
    unsigned char*      m_pixelData;
}

- (id) initWithCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;
- (void) finished;
- (Pixel*) pixelsAtX:(int)x Y:(int)y;
- (Pixel) pixelAtX:(int)x Y:(int)y;
- (Color) meanColorInRect:(CGRect)rect;

@property (nonatomic, readonly) size_t  width;
@property (nonatomic, readonly) size_t  height;
@property (nonatomic, readonly) size_t  stride;

@end
