#import <opencv2/opencv.hpp>
#import "Contour.h"
// models
#import "ContourEdge.h"
// private
#import "ContourEdge+internal.h"
#import "Contour+internal.h"
// extras
#import "NSArray+extras.h"
#import "UIColor+extras.h"
#import "math.hpp"

using namespace cv;

// MARK: -
@implementation Contour
- (instancetype)initWithCVMat:(Mat)cvMat {
    self = [super init];
    self.opencvContour = cvMat.clone();

    cv::Rect boundingRect = cv::boundingRect(self.opencvContour);
    _size = self.opencvContour.total();
    _bounds = CGRectMake(boundingRect.x, boundingRect.y, boundingRect.width, boundingRect.height);
    _aspect = boundingRect.height / boundingRect.width;
    _mask = [self generateMaskFromContour: self.opencvContour];

    _area = contourArea(self.opencvContour);
    _moments = moments(self.opencvContour);

    _points = [self getPointsFromMat:self.opencvContour];
    _tangent = [self calculateTangent:self.opencvContour];
    _center = [self calculateCenter:self.opencvContour];
    _clx = [self projectContourPoints:self.points];
    _angle = atan2(self.tangent.y, self.tangent.x);

    double min = self.clx.min.floatValue;
    double max = self.clx.max.floatValue;
    _clxMin = CGPointMake(self.center.x + self.tangent.x * min, self.center.y + self.tangent.y * min);
    _clxMax = CGPointMake(self.center.x + self.tangent.x * max, self.center.y + self.tangent.y * max);
    _localxMin = min;
    _localxMax = max;

    _color = [UIColor randomColor];

    return self;
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@", Points: %li\n", (long)self.size];
    [formatedDesc appendFormat:@", Bounds: %@", NSStringFromCGRect(self.bounds)];
    [formatedDesc appendFormat:@", Center: %@\n", NSStringFromCGPoint(self.center)];
    [formatedDesc appendFormat:@", Tangent: %@\n", NSStringFromCGPoint(self.tangent)];
    [formatedDesc appendFormat:@", Area: %f\n", self.area];
    [formatedDesc appendFormat:@", ClxMin: %@", NSStringFromCGPoint(self.clxMin)];
    [formatedDesc appendFormat:@", ClxMax: %@", NSStringFromCGPoint(self.clxMax)];
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}

- (void)dealloc {
}

// MARK: -
- (NSMutableArray <NSValue *> *)getPointsFromMat:(Mat)mat {
    NSMutableArray <NSValue *> *points = @[].mutableCopy;
    for (int i = 0; i < mat.total(); i++) {
        cv::Point p = mat.at<cv::Point>(i);
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(p.x, p.y)]];
    }
    return points;
}

// MARK: - Contour projection
- (NSArray<NSNumber *> *)projectContourPoints:(NSArray<NSValue *> *)points {
    NSMutableArray *dots = @[].mutableCopy;
    for (int i = 0; i < self.size; i++) {
        CGPoint p = [points[i] CGPointValue];
        double projected = [self projectPoint:p];
        [dots addObject:[NSNumber numberWithDouble:projected]];
    }
    return dots;
}

- (double)projectPoint:(CGPoint)point {
    Point2d t = Point2d(self.tangent.x, self.tangent.y);
    Point2d c = Point2d(self.center.x, self.center.y);
    Point2d d = Point2d(point.x, point.y) - c;
    return t.ddot(d);
}

// MARK: - Attribute calculation
- (CGPoint)calculateCenter:(Mat)mat {
    double area = self.moments.m00;
    double m10 = self.moments.m10;
    double m01 = self.moments.m01;
    double meanX = m10 / area;
    double meanY = m01 / area;

    double centerPoints[2] = {meanX, meanY};
    Mat center = Mat(2, 1, CV_64FC1, &centerPoints);

    double x = center.at<double>(0, 0);
    double y = center.at<double>(1, 0);

    return CGPointMake(x, y);
}

- (CGPoint)calculateTangent:(Mat)mat {
    double area = self.moments.m00;
    double mu20 = self.moments.mu20;
    double mu11 = self.moments.mu11;
    double mu02 = self.moments.mu02;

    double data[4] = {mu20, mu11, mu11, mu02};
    Mat momentsMatrix = Mat(2, 2, CV_64FC1, &data);
    momentsMatrix /= area;

    Mat svdW;
    Mat svdU;
    Mat svdVT;
    SVDecomp(momentsMatrix, svdW, svdU, svdVT);

    Mat tangent = svdU.col(0).clone();

    double x = tangent.at<double>(0, 0);
    double y = tangent.at<double>(0, 1);
    return CGPointMake(x, y);
}

- (double)contourOverlap:(Contour *)otherContour {
    double xmin = [self projectPoint:otherContour.clxMin];
    double xmax = [self projectPoint:otherContour.clxMax];
    double clxMin = self.clx.min.doubleValue;
    double clxMax = self.clx.max.doubleValue;
    CGPoint localRng = CGPointMake(clxMin, clxMax);
    CGPoint projectedRng = CGPointMake(xmin, xmax);

    return MIN(localRng.y, projectedRng.y) - MAX(localRng.x, projectedRng.x);
}

// MARK: -
- (void)getBoundingVertices:(cv::Point *)vertices {
    RotatedRect rect = minAreaRect(self.opencvContour);
    Point2f pts[4];
    rect.points(pts);

    // Convert them to cv::Point type
    for(int i = 0; i < 4; ++i)
        vertices[i] = pts[i];
}

// MARK: -
- (ContourEdge *)contourEdgeWithAdjacentContour:(Contour *)otherContour {
    Contour *contourA = self;
    Contour *contourB = otherContour;
    if (contourA.clxMin.x > contourB.clxMax.x) {
        contourA = otherContour;
        contourB = self;
    }

    Point2f overallTangent = [self convert:contourB.center] - [self convert:contourA.center];
    double overallAngle = atan2(overallTangent.y, overallTangent.x);
    double deltaAngle = MAX(math::angleDistance(contourA.angle, overallAngle),
                            math::angleDistance(contourB.angle, overallAngle)) * 180 / M_PI;

    double xOverlapA = [contourA contourOverlap:contourB];
    double xOverlapB = [contourB contourOverlap:contourA];
    double xOverlap = MAX(xOverlapA, xOverlapB);

    Point2f minMaxDiff = [self convert:contourB.clxMin] - [self convert:contourA.clxMax];
    double dist = norm(minMaxDiff);
    return [[ContourEdge alloc] initWithDistance:dist angle:deltaAngle overlap:xOverlap contourA:contourA contourB:contourB];
}

- (Mat)generateMaskFromContour:(cv::Mat)mat {
    int originx = int(self.bounds.origin.x);
    int originy = int(self.bounds.origin.y);
    int width = int(self.bounds.size.width);
    int height = int(self.bounds.size.height);

    Mat tight_mask = Mat::zeros(height, width, CV_32FC1);
    Mat tight_contour = Mat(mat);

    int rowCnt = tight_contour.rows;
    for (int h = 0; h < rowCnt; h++) {
        int tightX = tight_contour.at<int>(h, 0);
        int tightY = tight_contour.at<int>(h, 1);
        tight_mask.at<float>(tightY - originy, tightX - originx) = 1.0;
    }
    return tight_mask;
}

- (cv::Point2f)convert:(CGPoint)p {
    return Point2f(p.x, p.y);
}

@end
