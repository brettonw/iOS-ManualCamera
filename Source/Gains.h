typedef struct {
    float   red;
    float   green;
    float   blue;
} Gains;
Gains makeGains (float r, float g, float b, float limit);
Gains makeGainsWhite (Gains input, float r, float g, float b, float limit);
BOOL gainsAreEquivalent(Gains left, Gains right);
