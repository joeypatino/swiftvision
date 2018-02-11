#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"

@interface Contour ()
@property (nonatomic, assign) cv::Mat mat;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithCVMat:(cv::Mat)cvMat NS_DESIGNATED_INITIALIZER;
- (void)vertices:(cv::Point *)pts;
- (cv::Mat)tightMask;
@end

@interface UIImageContours ()
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, assign) cv::Mat inputImage;
@end

using namespace std;
using namespace cv;

@implementation UIImageContours
// MARK: -
- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    self.image = image;
    self.inputImage = [self grayScaleMat:image];
    self.contours = [self processContours: self.inputImage];

    return self;
}

// MARK: -

- (NSInteger)count {
    return self.contours.count;
}

- (Contour *)objectAtIndexedSubscript:(NSInteger)idx {
    return self.contours[idx];
}

// MARK: -

- (UIImage *)render {
    return [[UIImage alloc] initWithCVMat:[self.contours[0] tightMask]];
}

- (UIImage *)render:(BOOL (^)(Contour *c))filter {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline filtered:filter];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode filtered:(BOOL (^)(Contour *c))filter {
    BOOL fillConvexPolys = false;
    cv::Scalar contourColor = [self scalarColorFrom:color];

    cv::Mat outImage = cv::Mat::zeros(self.image.size.height, self.image.size.width, CV_8UC3);
    cv::Mat hull = cv::Mat::zeros(self.image.size.height, self.image.size.width, CV_8UC1);
    std::vector<std::vector<cv::Point> > contours;

    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        if (filter)
            if (!filter(contour))
                continue;

        if (fillConvexPolys) {
            cv::Point vertices[4];
            [contour vertices:vertices];
            cv::fillConvexPoly(outImage, vertices, 4, [self scalarColorFrom:[UIColor whiteColor]]);
        }
        contours.push_back(contour.mat);
    }

    BOOL filled = (mode == ContourRenderingModeFill) ? ContourRenderingModeFill : ContourRenderingModeOutline;
    cv::drawContours(outImage, contours, -1, contourColor, filled ? -1 : 1);

    return [[UIImage alloc] initWithCVMat:outImage];
}

// MARK: -

- (NSArray<Contour *> *)processContours:(cv::Mat)cvMat {
    NSMutableArray <Contour *> *foundContours = @[].mutableCopy;
    std::vector<std::vector<cv::Point> > contours;

    cv::findContours(cvMat, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);
    cv::Mat outImage = cv::Mat(contours);

    for (int j = 0; j < outImage.total(); j++) {
        cv::Mat contour = cv::Mat(outImage.at<std::vector<cv::Point>>(j));
        if (contour.empty()) continue;
        [foundContours addObject:[[Contour alloc] initWithCVMat:contour.clone()]];
    }
    return foundContours;
}

- (cv::Mat)grayScaleMat:(UIImage *)image {
    cv::Mat inputImage = [image mat];
    cv::Mat outImage;
    cv::cvtColor(inputImage, outImage, cv::COLOR_RGBA2GRAY);

    return outImage;
}

- (cv::Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return cv::Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}

@end
