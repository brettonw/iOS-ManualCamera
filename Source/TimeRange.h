#import "Time.h"

typedef struct {
    Time    low;
    Time    high;
} TimeRange;

TimeRange makeTimeRange(Time low, Time high);
Time clampTimeToRange(Time value, TimeRange range);