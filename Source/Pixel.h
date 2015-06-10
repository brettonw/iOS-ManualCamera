typedef struct {
    unsigned int    b:8;
    unsigned int    g:8;
    unsigned int    r:8;
    unsigned int    a:8;
} Pixel;

#define GRAYSCALE(pixel)    ((pixel.r + pixel.g + pixel.b) / (3.0 * 255.0))

