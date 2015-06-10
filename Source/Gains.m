#import "Gains.h"
#import "FloatMath.h"

Gains   makeGains(float red, float green, float blue, float limit) {
    Gains   gains;
    // normalize the corrections to compute the gains
    float   min = MIN(MIN(red, green), blue);
    gains.red = MIN(red / min, limit);
    gains.green = MIN(green / min, limit);
    gains.blue = MIN(blue / min, limit);
    return gains;
}

Gains   makeGainsWhite (Gains input, float r, float g, float b, float limit) {
    // compute new corrections
    float max = MAX(MAX(r, g), b);
    float red = (input.red + (input.red * (max / r))) / 2;
    float green = (input.green + (input.green * (max / g))) / 2;
    float blue = (input.blue + (input.blue * (max / b))) / 2;
    return makeGains(red, green, blue, limit);
}

BOOL gainsAreEquivalent(Gains left, Gains right) {
    return
        floatsAreEquivalent(left.red, right.red) AND
        floatsAreEquivalent(left.green, right.green) AND
        floatsAreEquivalent(left.blue, right.blue);
}
