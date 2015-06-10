#import "FloatMath.h"

BOOL floatsAreEquivalentEpsilon(float left, float right, float epsilon) {
    return (ABS(left - right) < epsilon);
}

BOOL floatsAreEquivalent(float left, float right) {
    return floatsAreEquivalentEpsilon(left, right, EPSILON);
}