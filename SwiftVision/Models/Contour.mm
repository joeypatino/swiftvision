#import <opencv2/opencv.hpp>
#import "functions.h"
#import "NSArray+extras.h"
#import "Contour.h"
#import "ContourEdge.h"

@interface Contour ()
@property (nonatomic, assign, readonly) CGPoint clxMin;
@property (nonatomic, assign, readonly) CGPoint clxMax;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull clx;
@property (nonatomic, assign, readonly) CGPoint *_Nonnull points;
@property (nonatomic, assign) cv::Mat mat;
@property (nonatomic, assign) cv::Moments moments;
@end

@interface ContourEdge ()
- (instancetype _Nonnull)initWithDistance:(double)distance
                                    angle:(double)angle
                                  overlap:(double)xOverlap
                                 contourA:(Contour *_Nonnull)contourA
                                 contourB:(Contour *_Nonnull)contourB NS_DESIGNATED_INITIALIZER;
@end

// MARK: -
@implementation Contour
- (instancetype)initWithCVMat:(cv::Mat)cvMat {
    self = [super init];
    self.mat = cvMat.clone();
    self.mat.push_back(self.mat.at<cv::Point>(0, 0));

    cv::Rect boundingRect = cv::boundingRect(self.mat);
    _size = self.mat.total();
    _bounds = CGRectMake(boundingRect.x, boundingRect.y, boundingRect.width, boundingRect.height);
    _aspect = boundingRect.height / boundingRect.width;

    _area = cv::contourArea(self.mat);
    _moments = cv::moments(self.mat);

    _points = [self cgPointsFromMat:self.mat];
    _tangent = [self calculateTangent:self.mat];
    _center = [self calculateCenter:self.mat];
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

// MARK: -
- (CGPoint*)cgPointsFromMat:(cv::Mat)mat {
    CGPoint *points = (CGPoint *)malloc(sizeof(CGPoint) * mat.total());
    for (int i = 0; i < mat.total(); i++) {
        cv::Point p = mat.at<cv::Point>(i);
        points[i] = CGPointMake(p.x, p.y);
    }
    return points;
}

// MARK: - Contour projection
- (NSArray<NSNumber *> *)projectContourPoints:(CGPoint *)points {
    NSMutableArray *dots = @[].mutableCopy;
    for (int i = 0; i < self.size; i++) {
        CGPoint p = points[i];
        double projected = [self projectPoint:p];
        [dots addObject:[NSNumber numberWithDouble:projected]];
    }
    return dots;
}

- (double)projectPoint:(CGPoint)point {
    cv::Point2d t = cv::Point2d(self.tangent.x, self.tangent.y);
    cv::Point2d c = cv::Point2d(self.center.x, self.center.y);
    cv::Point2d d = cv::Point2d(point.x, point.y) - c;
    return t.ddot(d);
}

- (CGPoint)calculateCenter:(cv::Mat)mat {
    double area = self.moments.m00;
    double m10 = self.moments.m10;
    double m01 = self.moments.m01;
    double meanX = m10 / area;
    double meanY = m01 / area;

    double centerPoints[2] = {meanX, meanY};
    cv::Mat center = cv::Mat(2, 1, CV_64FC1, &centerPoints);

    double x = center.at<double>(0, 0);
    double y = center.at<double>(1, 0);

    return CGPointMake(x, y);
}

- (CGPoint)calculateTangent:(cv::Mat)mat {
    double area = self.moments.m00;
    double mu20 = self.moments.mu20;
    double mu11 = self.moments.mu11;
    double mu02 = self.moments.mu02;

    double data[4] = {mu20, mu11, mu11, mu02};
    cv::Mat momentsMatrix = cv::Mat(2, 2, CV_64FC1, &data);
    momentsMatrix /= area;

    cv::Mat svdW;
    cv::Mat svdU;
    cv::Mat svdVT;
    cv::SVDecomp(momentsMatrix, svdW, svdU, svdVT);

    cv::Mat tangent = svdU.col(0).clone();

    double x = tangent.at<double>(0, 0);
    double y = tangent.at<double>(0, 1);
    return CGPointMake(x, y);
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
    free(self.points);
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
    double deltaAngle = MAX(angleDistance(contourA.angle, overallAngle), angleDistance(contourB.angle, overallAngle)) * 180 / M_PI;

    double xOverlapA = [contourA contourOverlap:contourB];
    double xOverlapB = [contourB contourOverlap:contourA];
    double xOverlap = MAX(xOverlapA, xOverlapB);

    cv::Point2d minMaxDiff = cv::Point2d(contourB.clxMin.x - contourA.clxMax.x, contourB.clxMin.y - contourA.clxMax.y);
    double dist = cv::norm(cv::Mat(minMaxDiff));

    double EDGE_MAX_OVERLAP = 1.0;   // max px horiz. overlap of contours in span
    double EDGE_MAX_LENGTH = 100.0;  // max px length of edge connecting contours
    double EDGE_MAX_ANGLE = 25.0;    // maximum change in angle allowed between contours

    //cv::reshape(?, ?);
    //cv::reduce(self.mat, self.mat, 0, 0);
    //cv::transform(self.mat, self.mat, cv::Matx13f(1,1,1))

    if (dist > EDGE_MAX_LENGTH || xOverlap > EDGE_MAX_OVERLAP || deltaAngle > EDGE_MAX_ANGLE) {
        return nil;
    } else {
        return [[ContourEdge alloc] initWithDistance:dist angle:deltaAngle overlap:xOverlap contourA:contourA contourB:contourB];
    }
}

- (double)contourOverlap:(Contour *)otherContour {
    double xmin = [self projectPoint:otherContour.clxMin];
    double xmax = [self projectPoint:otherContour.clxMax];
    double clxMin = [[self.clx min] doubleValue];
    double clxMax = [[self.clx max] doubleValue];
    CGPoint localRng = CGPointMake(clxMin, clxMax);
    CGPoint projectedRng = CGPointMake(xmin, xmax);

    return intervalOverlap(localRng, projectedRng);
}

// MARK: -
- (void)getBoundingVertices:(cv::Point *)vertices {
    cv::RotatedRect rect = cv::minAreaRect(self.mat);
    cv::Point2f pts[4];
    rect.points(pts);

    // Convert them to cv::Point type
    for(int i = 0; i < 4; ++i)
        vertices[i] = pts[i];
}

- (cv::Mat)mask {
    CGRect b = self.bounds;

    const int x = int(b.origin.x);
    const int y = int(b.origin.y);
    const int w = int(b.size.width);
    const int h = int(b.size.height);
    cv::Mat cvMat = cv::Mat(self.mat);
    cv::Mat tight_mask = cv::Mat::zeros(w, h, CV_8UC3);
    cv::Mat arr = cv::Mat({x, y});
    cv::Mat reshapedArr = arr.reshape(0, 1);
    cv::Mat convertedArr;
    reshapedArr.convertTo(convertedArr, CV_64F);

    cv::Mat tight_contour = cvMat - convertedArr;
    cv::drawContours(tight_mask, {tight_contour}, 0, cv::Scalar(255, 255, 255), -1);

    return tight_mask;
}

@end
