#import <opencv2/opencv.hpp>
#import "Contour.h"

@interface Contour ()
@property (nonatomic, assign) cv::Mat mat;
@end

#define ContourBasicDebugInfo
//#define ContourDetailedDebugInfo

void describe_mat( cv::Mat mat, char const *name ) {

    printf("\n############ %s ############\n", name);
    printf("type: %i\n", mat.type());
    printf("depth: %i\n", mat.depth());
    printf("channels: %i\n", mat.channels());
    printf("size: {%i,%i}\n", mat.size().width, mat.size().height);
    printf("----------------------------\n");

    for (int i = 0; i < mat.cols; ++i) {
        const int *columValues = mat.ptr<int>(i);
        printf("[");
        for (int j = 0; j < mat.rows; ++j) {
            printf("%i", columValues[j]);
            if (j < mat.rows - 1){
                printf(", ");
            }
        }
        printf("]\n");
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

    for (int i = 0; i < self.mat.total(); i++) {
        cv::Point p = self.mat.at<cv::Point>(i);
        _points[i] = CGPointMake(p.x, p.y);
    }

    return self;
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
- (void)vertices:(cv::Point *)vertices {
    cv::RotatedRect rect = cv::minAreaRect(self.mat);
    cv::Point2f pts[4];
    rect.points(pts);

    // Convert them to cv::Point type
    for(int i = 0; i < 4; ++i)
        vertices[i] = pts[i];
}

- (cv::Mat)tightMask {
    /**
     tight_mask = np.zeros((height, width), dtype=np.uint8)
     diff = np.array((xmin, ymin)).reshape((-1, 1, 2))
     tight_contour = contour - diff

     cv2.drawContours(tight_mask, [tight_contour], 0, (1, 1, 1), -1)
     */
    printf("::::tightMask::::\n");
    CGRect b = CGRectMake(401, 649, 49, 4); //self.bounds;

    const int x = int(b.origin.x);
    const int y = int(b.origin.y);
    const int w = int(b.size.width);
    const int h = int(b.size.height);
    printf("{%i,%i,%i,%i}", x, y, w, h);

    cv::Mat cvMat = cv::Mat(self.mat);
    describe_mat(cvMat.t(), "cvMat");

    cv::Mat tight_mask = cv::Mat::zeros(w, h, CV_8UC3);
    describe_mat(tight_mask.t(), "tight_mask");

    cv::Mat arr = cv::Mat({x, y});
    describe_mat(arr.t(), "arr");

    cv::Mat reshapedArr = arr.reshape(0, 1);
    describe_mat(reshapedArr.t(), "reshapedArr");

//    cv::Mat mergedArr;
//    cv::Mat input[] = {reshapedArr, reshapedArr, reshapedArr};
//    cv::merge(input, 3, mergedArr);
//    describe_mat(mergedArr.t(), "mergedArr");

    cv::Mat convertedArr;
    reshapedArr.convertTo(convertedArr, CV_64F);
    describe_mat(convertedArr.t(), "convertedArr");


    cv::Mat tight_contour = cvMat - convertedArr;
    describe_mat(tight_contour, "tight_contour");

    cv::drawContours(tight_mask, {tight_contour}, 0, cv::Scalar(1, 1, 1), -1);
    describe_mat(tight_mask.t(), "tight_mask");

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
