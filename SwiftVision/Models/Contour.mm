#import <opencv2/opencv.hpp>
#import "NSArray+flatten.h"
#import "Contour.h"
#import "ContourEdge.h"

@interface Contour ()
@property (nonatomic, assign) cv::Mat mat;
@end

#define ContourBasicDebugInfo
//#define ContourDetailedDebugInfo

void describe_vector(std::vector<double> vector, char const *name ) {
    printf("\n############ %s ############\n", name);
    printf("size: {%zul}\n", vector.size());
    printf("----------------------------\n");

    std::vector<double>::iterator it = vector.begin();
    std::vector<double>::iterator const end = vector.end();

    for (; it != end; it++) {
        double p = *it;
        printf("{%f}", p);
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}

void describe_vector(std::vector<cv::Point> vector, char const *name ) {
    printf("\n############ %s ############\n", name);
    printf("size: {%zul}\n", vector.size());
    printf("----------------------------\n");

    std::vector<cv::Point>::iterator it = vector.begin();
    std::vector<cv::Point>::iterator const end = vector.end();

    for (; it != end; it++) {
        cv::Point p = *it;
        printf("{%i,%i}", p.x, p.y);
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}

void describe_vector( cv::Mat mat, char const *name ) {
    printf("\n############ cv::Mat::%s ############\n", name);
    printf("type: %i\n", mat.type());
    printf("depth: %i\n", mat.depth());
    printf("dims: %i\n", mat.dims);
    printf("channels: %i\n", mat.channels());
    printf("size: {");
    for (int i = 0; i < mat.dims; ++i) {
        printf("%i", mat.size[i]);
        if (i < mat.dims - 1){ printf(", "); }
    }
    printf(", %i", mat.cols);
    printf("}\n");
    printf("total: %zul\n", mat.total());
    printf("----------------------------\n");

    for (int i = 0; i < mat.cols; ++i) {
        double *columValues = mat.ptr<double>(i);
        printf("[");
        for (int j = 0; j < mat.rows; ++j) {
            printf("%f", columValues[j]);
            if (j < mat.rows - 1){
                printf(", ");
            }
        }
        printf("]\n");
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}

void describe_vectord(std::vector<std::vector<double>> vector, char const *name ) {
    printf("\n############ %s ############\n", name);
    printf("size: {%zul}\n", vector.size());
    printf("----------------------------\n");

    std::vector<std::vector<double>>::iterator it = vector.begin();
    std::vector<std::vector<double>>::iterator const end = vector.end();

    for (; it != end; it++) {
        std::vector<double> inner = *it;
        std::vector<double>::iterator innerIt = inner.begin();
        std::vector<double>::iterator const innerEnd = inner.end();

        for (; innerIt != innerEnd; innerIt++) {
            double val = *innerIt;
            printf("{%f}", val);
        }
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}

double angleDistance(double angle_b, double angle_a) {
    double diff = angle_b - angle_a;

    while (diff > M_PI) {
        diff -= 2 * M_PI;
    }
    while (diff < -M_PI) {
        diff += 2 * M_PI;
    }
    return abs(diff);
}

double intervalOverlap(CGPoint int_a, CGPoint int_b) {
    return MIN(int_a.y, int_b.y) - MAX(int_a.x, int_b.x);
}

// MARK: -
@implementation Contour
- (instancetype)initWithCVMat:(cv::Mat)cvMat {
    self = [super init];
    self.mat = cvMat.clone();
    cv::Rect boundingRect = cv::boundingRect(self.mat);
    _size = self.mat.total();
    _bounds = CGRectMake(boundingRect.x, boundingRect.y, boundingRect.width, boundingRect.height);
    _aspect = boundingRect.height / boundingRect.width;

    _area = cv::contourArea(self.mat);
    _points = [self pointsFrom:self.mat];
    _tangent = [self calculateTangent:self.mat];
    _center = [self calculateCenter:self.mat];
    _clx = [self projectPoints:self.points];

    double min = [[self.clx min] floatValue];
    double max = [[self.clx max] floatValue];
    _clxMin = CGPointMake(self.center.x + self.tangent.x * min, self.center.y + self.tangent.y * min);
    _clxMax = CGPointMake(self.center.x + self.tangent.x * max, self.center.y + self.tangent.y * max);

    return self;
}

// MARK: -
- (CGPoint*)pointsFrom:(cv::Mat)mat {
    CGPoint *points = (CGPoint *)malloc(sizeof(CGPoint) * mat.total());
    for (int i = 0; i < mat.total(); i++) {
        cv::Point p = mat.at<cv::Point>(i);
        points[i] = CGPointMake(p.x, p.y);
    }
    return points;
}

// MARK: - Contour projection
- (NSArray<NSNumber *> *)projectPoints:(CGPoint *)points {
    NSMutableArray *dots = @[].mutableCopy;

    for (int i = 0; i < self.size; i++) {
        CGPoint p = points[i];
        double projected = [self project:p];
        [dots addObject:[NSNumber numberWithDouble:projected]];
    }
    return dots;
}

- (double)project:(CGPoint)point {
    cv::Point2d t = cv::Point2d(self.tangent.x, self.tangent.y);
    cv::Point2d c = cv::Point2d(self.center.x, self.center.y);
    cv::Point2d d = cv::Point2d(point.x, point.y) - c;
    return t.ddot(d);
}

- (CGPoint)calculateCenter:(cv::Mat)mat {
    cv::Moments moments = cv::moments(mat);

    double area = moments.m00;
    double m10 = moments.m10;
    double m01 = moments.m01;
    double meanX = m10 / area;
    double meanY = m01 / area;

    double centerPoints[2] = {meanX, meanY};
    cv::Mat center = cv::Mat(2, 1, CV_64FC1, &centerPoints);

    double x = center.at<double>(0, 0);
    double y = center.at<double>(1, 0);
    return CGPointMake(x, y);
}

- (double)angle {
    return atan2(self.tangent.y, self.tangent.x);
}

- (CGPoint)calculateTangent:(cv::Mat)mat {
    cv::Moments moments = cv::moments(mat);

    double area = moments.m00;
    double mu20 = moments.mu20;
    double mu11 = moments.mu11;
    double mu02 = moments.mu02;

    double data[4] = {mu20, mu11, mu11, mu02};
    cv::Mat momentsMatrix = cv::Mat(2, 2, CV_64FC1, &data);
    momentsMatrix /= area;

    cv::Mat svdW;
    cv::Mat svdU;
    cv::Mat svdVT;
    cv::SVDecomp(momentsMatrix, svdW, svdU, svdVT);

    cv::Mat tangent = svdU.col(0).clone();

    double x = tangent.at<double>(0, 0);
    double y = tangent.at<double>(1, 0);
    return CGPointMake(x, y);
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@", POINTS: %li", (long)self.size];
#ifdef ContourBasicDebugInfo
    [formatedDesc appendFormat:@", BOUNDS: %@", [self shortDescription]];
#endif
#ifdef ContourDetailedDebugInfo
    [formatedDesc appendFormat:@", [%@]", [self longDescription]];
#endif
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}

- (void)dealloc {
    free(self.points);
}

// MARK: -
- (ContourEdge *)generateEdge:(Contour *)adjacentContour {
    Contour *contourA = self;
    Contour *contourB = adjacentContour;
    if (contourA.clxMin.x > contourB.clxMax.x) {
        contourA = adjacentContour;
        contourB = self;
    }

    double xOverlapA = [contourA local_overlap:contourB];
    double xOverlapB = [contourB local_overlap:contourA];   // why NaN !?

//    NSLog(@"xOverlapA:: %f", xOverlapA);
//    NSLog(@"xOverlapB:: %f", xOverlapB);

    CGPoint overallTangent = CGPointMake(contourB.center.x - contourA.center.x, contourB.center.y - contourA.center.y);
    double overallAngle = atan2(overallTangent.y, overallTangent.x);

    double deltaAngle = MAX(angleDistance(contourA.angle, overallAngle), angleDistance(contourB.angle, overallAngle)) * 180 / M_PI;

    double xOverlap = MAX(xOverlapA, xOverlapB);

    double dist = cv::norm(cv::Mat(cv::Point2d(contourB.clxMin.x - contourA.clxMin.x, contourB.clxMin.y - contourA.clxMin.y)));

    double EDGE_MAX_OVERLAP = 1.0;   // max reduced px horiz. overlap of contours in span
    double EDGE_MAX_LENGTH = 100.0;  // max reduced px length of edge connecting contours
    double EDGE_ANGLE_COST = 10.0;   // cost of angles in edges (tradeoff vs. length)
    double EDGE_MAX_ANGLE = 15.0;      // maximum change in angle allowed between contours

    if (dist > EDGE_MAX_OVERLAP || xOverlap > EDGE_MAX_LENGTH || deltaAngle > EDGE_MAX_ANGLE) {
        return nil;
    } else {
        double score = dist + deltaAngle * EDGE_ANGLE_COST;
        NSLog(@"score:: %f", score);
        return [[ContourEdge alloc] initWithScore:score contourA:contourA contourB:contourB];
    }
}

- (double)local_overlap:(Contour *)other {
    double xmin = [self project:other.clxMin];
    double xmax = [self project:other.clxMax];
    double clxMin = [[self.clx min] doubleValue];
    double clxMax = [[self.clx max] doubleValue];
    CGPoint localRng = CGPointMake(clxMin, clxMax);
    CGPoint projectedRng = CGPointMake(xmin, xmax);
    printf("intervalOverlap:: %f\n", intervalOverlap(localRng, projectedRng));

    return intervalOverlap(localRng, projectedRng);
}

// MARK: -
- (void)vertices:(cv::Point *)vertices {
    cv::RotatedRect rect = cv::minAreaRect(self.mat);
    cv::Point2f pts[4];
    rect.points(pts);

    // Convert them to cv::Point type
    for(int i = 0; i < 4; ++i)
        vertices[i] = pts[i];
}

- (cv::Mat)tightMask {
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

// MARK: -

- (NSString *)longDescription {
    NSMutableString *description = [NSMutableString string];
    for (int idx = 0; idx < self.size; idx++) {
        [description appendFormat:@"%@", NSStringFromCGPoint(self.points[idx])];
        if (idx < self.size - 1) [description appendFormat:@", "];
    }
    return description;
}

- (NSString *)shortDescription {
    return [NSString stringWithFormat:@"%@", NSStringFromCGRect(self.bounds)];
}

@end
