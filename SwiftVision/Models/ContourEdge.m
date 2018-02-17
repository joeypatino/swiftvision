#import "ContourEdge.h"

@implementation ContourEdge
- (instancetype _Nonnull)initWithDistance:(double)distance angle:(double)angle overlap:(double)overlap contourA:(Contour *_Nonnull)contourA contourB:(Contour *_Nonnull)contourB {
    self = [super init];
    _distance = distance;
    _angle = angle;
    _overlap = overlap;
    _contourA = contourA;
    _contourB = contourB;
    return self;
}

- (double)score {
    double EDGE_ANGLE_COST = 10.0;   // cost of angles in edges (tradeoff vs. length)
    return self.distance + self.angle * EDGE_ANGLE_COST;
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@", Distance: %f", self.distance];
    [formatedDesc appendFormat:@", Angle: %f", self.angle];
    [formatedDesc appendFormat:@", Overlap: %f", self.overlap];
    [formatedDesc appendFormat:@", Score: %f", self.score];
    [formatedDesc appendFormat:@">"];

    return formatedDesc;
}

@end
