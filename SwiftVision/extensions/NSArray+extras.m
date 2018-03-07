#import "NSArray+extras.h"

@implementation NSArray (extras)
- (NSNumber *)min {
    float xmin = MAXFLOAT;
    for (NSNumber *num in self) {
        float x = num.floatValue;
        if (x < xmin) xmin = x;
    }
    return [NSNumber numberWithFloat:xmin];
}

- (NSNumber *)max {
    float xmax = -MAXFLOAT;
    for (NSNumber *num in self) {
        float x = num.floatValue;
        if (x > xmax) xmax = x;
    }
    return [NSNumber numberWithFloat:xmax];
}

- (NSNumber *)median {
    return [[self sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:[self count] / 2];
}
@end
