#import <opencv2/opencv.hpp>
#include <valarray>
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

// MARK: -
@implementation Contour
- (instancetype)initWithCVMat:(cv::Mat)cvMat {
    self = [super init];
    self.mat = cvMat.clone();
    cv::Rect boundingRect = cv::boundingRect(self.mat);

    _size = self.mat.total();
    _bounds = CGRectMake(boundingRect.x, boundingRect.y, boundingRect.width, boundingRect.height);
    _points = (CGPoint *)malloc(sizeof(CGPoint) * _size);
    _aspect = boundingRect.height / boundingRect.width;
    _area = cv::contourArea(self.mat);

    _tangent = [self calculateTangent:self.mat];

    for (int i = 0; i < self.mat.total(); i++) {
        cv::Point p = self.mat.at<cv::Point>(i);
        _points[i] = CGPointMake(p.x, p.y);
    }

    return self;
}

- (double)calculateTangent:(cv::Mat)mat {
    cv::Moments moments = cv::moments(mat);

    double area = 26.5; //moments.m00;
    printf("area:: %f\n", area);
    double m10 = 11493.8333333; //moments.m10
    double m01 = 17255.3333333; //moments.m01
    double mu20 = 1080.81184486; //moments.mu20
    double mu11 = -67.9216457019; //moments.mu11
    double mu02 = 14.1954926644; //moments.mu02

    double meanX = m10 / area;
    double meanY = m01 / area;
    printf("meanX:: %f\n", meanX);
    printf("meanY:: %f\n", meanY);

    double data[4] = {mu20, mu11, mu11, mu02};
    cv::Mat momentsMatrix = cv::Mat(2, 2, CV_64FC1, &data);
    momentsMatrix /= area;
    describe_vector(momentsMatrix, "momentsMatrix");

    cv::Mat svdW;
    cv::Mat svdU;
    cv::Mat svdVT;
    cv::SVDecomp(momentsMatrix, svdW, svdU, svdVT);
    describe_vector(svdU, "svdU");

    double centerPoints[2] = {meanX, meanY};
    cv::Mat center = cv::Mat(2, 1, CV_64FC1, &centerPoints);
    describe_vector(center, "center");

    cv::Mat tangent = svdU.col(0).clone();
    describe_vector(tangent, "tangent");

    return 0;
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
    /*
     # we want a left of b (so a's successor will be b and b's
     # predecessor will be a) make sure right endpoint of b is to the
     # right of left endpoint of a.
    if cinfo_a.point0[0] > cinfo_b.point1[0]:
        tmp = cinfo_a
        cinfo_a = cinfo_b
        cinfo_b = tmp

        x_overlap_a = cinfo_a.local_overlap(cinfo_b)
        x_overlap_b = cinfo_b.local_overlap(cinfo_a)

        overall_tangent = cinfo_b.center - cinfo_a.center
        overall_angle = np.arctan2(overall_tangent[1], overall_tangent[0])

        delta_angle = max(angle_dist(cinfo_a.angle, overall_angle),
                          angle_dist(cinfo_b.angle, overall_angle)) * 180/np.pi

        # we want the largest overlap in x to be small
        x_overlap = max(x_overlap_a, x_overlap_b)

        dist = np.linalg.norm(cinfo_b.point0 - cinfo_a.point1)

        if (dist > EDGE_MAX_LENGTH or
            x_overlap > EDGE_MAX_OVERLAP or
            delta_angle > EDGE_MAX_ANGLE):
            return None
            else:
                score = dist + delta_angle*EDGE_ANGLE_COST
                return (score, cinfo_a, cinfo_b)
*/

    return nil;
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
//    describe_vector(cvMat.t(), "contour");
    cv::Mat tight_mask = cv::Mat::zeros(w, h, CV_8UC3);
//    describe_vector(tight_mask.t(), "tight_mask");
    cv::Mat arr = cv::Mat({x, y});
//    describe_vector(arr.t(), "arr");
    cv::Mat reshapedArr = arr.reshape(0, 1);
//    describe_vector(reshapedArr.t(), "reshapedArr");
    cv::Mat convertedArr;
    reshapedArr.convertTo(convertedArr, CV_64F);
//    describe_vector(convertedArr.t(), "convertedArr");

    cv::Mat tight_contour = cvMat - convertedArr;
//    describe_vector(tight_contour, "tight_contour");
    cv::drawContours(tight_mask, {tight_contour}, 0, cv::Scalar(255, 255, 255), -1);
//    describe_vector(tight_mask.t(), "tight_mask");

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
