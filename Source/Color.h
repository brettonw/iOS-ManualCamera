typedef struct {
    float red;
    float green;
    float blue;
} Color;

Color makeColor(float red, float green, float blue);
Color makeGrayColor(float gray);
float colorGrayValue(Color color);
