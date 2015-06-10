#import "Time.h"

Time makeTime(int count, int scale) {
    Time    time;
    time.count = count;
    time.scale = scale;
    return time;
}

BOOL timesAreEquivalent(Time left, Time right) {
    return (left.scale > 0) AND (right.scale > 0) AND
        ((left.count * right.scale) == (right.count * left.scale));
}
