#import <opencv2/opencv.hpp>
#import "functions.h"
#import "NSArray+extras.h"
#import "Contour.h"
#import "ContourEdge.h"
#import "ContourEdge+internal.h"
#import "Contour+internal.h"

using namespace std;
using namespace cv;

@interface Contour ()
@property (nonatomic, assign, readonly) CGPoint clxMin;
@property (nonatomic, assign, readonly) CGPoint clxMax;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull clx;
@property (nonatomic, assign, readonly) NSArray <NSValue *> *_Nonnull points;
@property (nonatomic, assign) Moments moments;

@property (nonatomic, assign, readonly) uchar *maskData;
@end

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

    double min = [[self.clx min] floatValue];
    double max = [[self.clx max] floatValue];
    _clxMin = CGPointMake(self.center.x + self.tangent.x * min, self.center.y + self.tangent.y * min);
    _clxMax = CGPointMake(self.center.x + self.tangent.x * max, self.center.y + self.tangent.y * max);
    _localxMin = min;
    _localxMax = max;

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
    free(self.maskData);
}

// MARK: -
- (NSMutableArray <NSValue *> *)getPointsFromMat:(Mat)mat {
    NSMutableArray <NSValue *> *points = @[].mutableCopy;
    for (int i = 0; i < mat.total() / 2; i++) {
        cv::Point p = mat.at<cv::Point>(i);
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(p.x, p.y)]];
    }
    return points;
}

// MARK: - Contour projection
- (NSArray<NSNumber *> *)projectContourPoints:(NSArray<NSValue *> *)points {
    NSMutableArray *dots = @[].mutableCopy;
    for (int i = 0; i < self.size / 2; i++) {
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
    double clxMin = [[self.clx min] doubleValue];
    double clxMax = [[self.clx max] doubleValue];
    CGPoint localRng = CGPointMake(clxMin, clxMax);
    CGPoint projectedRng = CGPointMake(xmin, xmax);

    return geom::intervalOverlap(localRng, projectedRng);
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

    CGPoint overallTangent = CGPointMake(contourB.center.x - contourA.center.x, contourB.center.y - contourA.center.y);
    double overallAngle = atan2(overallTangent.y, overallTangent.x);
    double deltaAngle = MAX(geom::angleDistance(contourA.angle, overallAngle),
                            geom::angleDistance(contourB.angle, overallAngle)) * 180 / M_PI;

    double xOverlapA = [contourA contourOverlap:contourB];
    double xOverlapB = [contourB contourOverlap:contourA];
    double xOverlap = MAX(xOverlapA, xOverlapB);

    Point2d minMaxDiff = Point2d(contourB.clxMin.x - contourA.clxMax.x, contourB.clxMin.y - contourA.clxMax.y);
    double dist = norm(Mat(minMaxDiff));

    double EDGE_MAX_OVERLAP = 1.0;   // max px horiz. overlap of contours in span
    double EDGE_MAX_LENGTH = 100.0;  // max px length of edge connecting contours
    double EDGE_MAX_ANGLE = 25.0;    // maximum change in angle allowed between contours

    //reshape(?, ?);
    //reduce(self.mat, self.mat, 0, 0);
    //transform(self.mat, self.mat, Matx13f(1,1,1))

//    NSLog(@"dist: %f", dist);
//    NSLog(@"deltaAngle: %f", deltaAngle);
//    NSLog(@"xOverlap: %f", xOverlap);

    if (dist > EDGE_MAX_LENGTH || xOverlap > EDGE_MAX_OVERLAP || deltaAngle > EDGE_MAX_ANGLE) {
        return nil;
    } else {
        return [[ContourEdge alloc] initWithDistance:dist angle:deltaAngle overlap:xOverlap contourA:contourA contourB:contourB];
    }
}

- (Mat)generateMaskFromContour:(cv::Mat)mat {
    int originx = int(self.bounds.origin.x);
    int originy = int(self.bounds.origin.y);
    int width = int(self.bounds.size.width);
    int height = int(self.bounds.size.height);

    Mat tight_mask = Mat::zeros(height, width, CV_32S);
    Mat tight_contour = Mat(mat);

    int rowCnt = tight_contour.rows;
    for (int h = 0; h < rowCnt; h++) {
        int tightX = tight_contour.at<int>(h, 0);
        int tightY = tight_contour.at<int>(h, 1);
        tight_mask.at<int>(tightY - originy, tightX - originx) = 1;
    }

    return tight_mask;
}
@end
