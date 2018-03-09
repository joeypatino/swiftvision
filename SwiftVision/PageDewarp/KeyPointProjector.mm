#import <opencv2/opencv.hpp>
#import "KeyPointProjector.h"
#import "functions.h"

@implementation KeyPointProjector

// MARK: -
- (NSArray <NSValue *> *)projectKeypoints:(NSArray <NSValue *> *)keyPoints of:(std::vector<double>)vectors {
    NSMutableArray <NSValue *> *projectedValues = @[].mutableCopy;
    for (NSValue *value in keyPoints) {
        int x = value.CGPointValue.x;
        int y = value.CGPointValue.y;
        float xvec = vectors[x];
        float yvec = vectors[y];
        CGPoint projectedPoint = CGPointMake(xvec, yvec);
        [projectedValues addObject:[NSValue valueWithCGPoint:projectedPoint]];
    }
    [projectedValues replaceObjectAtIndex:0 withObject:[NSValue valueWithCGPoint:CGPointZero]];
    return [self projectXY:projectedValues of:vectors];
}

- (NSArray <NSValue *> *)projectXY:(NSArray <NSValue *> *)xyCoordsArr of:(std::vector<double>)vectors {
    // slice [6] and [7]
    float alpha = vectors[6];
    float beta = vectors[7];

    std::vector<double> poly = {alpha + beta, -2*alpha - beta, alpha, 0};
    NSArray <NSNumber *> *xCoordsArr = nsarray::numbersAlongAxis(0, xyCoordsArr);
    std::vector<double> xCoords = nsarray::convertTo(xCoordsArr);
    std::vector<double> zCoords = math::polyval(poly, xCoords);
    logs::describe_vector(zCoords, "zCoords");

    std::vector<std::vector<double>> xyCoords = vectors::reshape(nsarray::convertTo(xyCoordsArr), int(xyCoordsArr.count), 2);
    logs::describe_vector(xyCoords, "xyCoords");

    std::vector<std::vector<double>> objPoints = vectors::hstack(xyCoords, vectors::reshape(zCoords, int(zCoords.size()), 1));
    logs::describe_vector(objPoints, "objPoints");

    //    [xyCoords + zCoords]

    return @[];
}

@end
