#import "NSArray+flatten.h"

@implementation NSArray (flatten)
- (void)flatten:(NSMutableArray *)original inArray:(NSMutableArray *)result {
    for(id element in original) {
        if([element isKindOfClass:[NSNumber class]])
            [result addObject:element];
        else
            [self flatten:element inArray:result];
    }
}

@end
