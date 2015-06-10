#import "FloatRange.h"

FloatRange makeFloatRange(float low, float high) {
    FloatRange  range;
    range.low = low;
    range.high = high;
    return range;
}

float clampFloatToRange(float value, FloatRange range) {
    return (value < range.low) ? range.low :
    (value > range.high) ? range.high :
    value;
}
