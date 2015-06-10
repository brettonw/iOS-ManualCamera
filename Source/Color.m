#import "Color.h"

Color makeColor(float red, float green, float blue) {
    Color color;
    color.red = red;
    color.green = green;
    color.blue = blue;
    return color;
}

Color makeGrayColor(float gray) {
    Color color;
    color.red = color.green = color.blue = gray;
    return color;
}

float colorGrayValue(Color color) {
    return (color.red + color.green + color.blue) / 3.0;
}
