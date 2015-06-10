#import "Time.h"

Time makeTime(int count, int scale) {
    Time    time;
    time.count = count;
    time.scale = scale;
    return time;
}

