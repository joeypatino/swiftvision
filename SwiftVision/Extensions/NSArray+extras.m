#import "NSArray+extras.h"

@implementation NSArray (extras)
- (void)flatten:(NSMutableArray *)original inArray:(NSMutableArray *)result {
    for(id element in original) {
        if([element isKindOfClass:[NSNumber class]])
            [result addObject:element];
        else
            [self flatten:element inArray:result];
    }
}

- (NSNumber * _Nullable)min {
    float xmin = MAXFLOAT;
    for (NSNumber *num in self) {
        float x = num.floatValue;
        if (x < xmin) xmin = x;
    }
    return [NSNumber numberWithFloat:xmin];
}

- (NSNumber * _Nullable)max {
    float xmax = -MAXFLOAT;
    for (NSNumber *num in self) {
        float x = num.floatValue;
        if (x > xmax) xmax = x;
    }
    return [NSNumber numberWithFloat:xmax];
}

@end
