typedef struct {
    int     count;
    int     scale;
} Time;

Time makeTime(int count, int scale);
BOOL timesAreEquivalent(Time left, Time right);
