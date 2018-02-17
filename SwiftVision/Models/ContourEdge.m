#import "ContourEdge.h"

@implementation ContourEdge
- (instancetype _Nonnull)initWithScore:(double)score
                              contourA:(Contour *_Nonnull)contourA
                              contourB:(Contour *_Nonnull)contourB {
    self = [super init];
    _score = score;
    _contourA = contourA;
    _contourB = contourB;
    return self;
}

@end
