#import "TimeRange.h"

TimeRange makeTimeRange(Time low, Time high) {
    TimeRange   timeRange;
    timeRange.low = low;
    timeRange.high = high;
    return timeRange;
}

int compareTime(Time left, Time right) {
    // convert the times to an equivalent scale, by multipying the counts by the
    // other time scale
    int leftCount = left.count * right.scale;
    int rightCount = right.count * left.scale;
    return leftCount - rightCount;
}

Time clampTimeToRange(Time time, TimeRange timeRange) {
    return  (compareTime(time, timeRange.low) < 0) ? timeRange.low :
    (compareTime(time, timeRange.high) > 0) ? timeRange.high :
    time;
}
