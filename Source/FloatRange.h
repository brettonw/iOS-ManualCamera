typedef struct {
    float low;
    float high;
} FloatRange;

FloatRange makeFloatRange(float low, float high);
float clampFloatToRange(float value, FloatRange range);

