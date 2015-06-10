typedef struct _Pixel {
    unsigned int    b:8;
    unsigned int    g:8;
    unsigned int    r:8;
    unsigned int    a:8;
} Pixel;

#define GRAYSCALE(pixel)    ((pixel.r + pixel.g + pixel.b) / (3.0 * 255.0))

@interface PixelBuffer : NSObject {
    CVPixelBufferRef    m_pixelBufferRef;
    size_t              m_bytesPerRow;
    unsigned char*      m_pixelData;
}

- (id) initWithCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;
- (void) finished;
- (Pixel*) pixelsAtX:(int)x Y:(int)y;
- (Pixel) pixelAtX:(int)x Y:(int)y;
- (UIColor*) meanColorInRect:(CGRect)rect;

@property (nonatomic, readonly) size_t  width;
@property (nonatomic, readonly) size_t  height;
@property (nonatomic, readonly) size_t  stride;

@end
