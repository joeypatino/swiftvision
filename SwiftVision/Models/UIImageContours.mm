#import <opencv2/opencv.hpp>
#import "UIImageContours.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"

@interface Contour ()
@property (nonatomic, assign) cv::Mat mat;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithCVMat:(cv::Mat)cvMat NS_DESIGNATED_INITIALIZER;
@end

@interface UIImageContours ()
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, assign) cv::Mat inputImage;
@end

@implementation UIImageContours
- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    self.image = image;
    self.inputImage = [self grayScaleMat:image];
    self.contours = [self processContours: self.inputImage];

    return self;
}

- (cv::Mat)grayScaleMat:(UIImage *)image {
    cv::Mat inputImage = [image mat];
    cv::Mat outImage;
    cv::cvtColor(inputImage, outImage, cv::COLOR_RGBA2GRAY);

    return outImage;
}

- (NSInteger)count {
    return self.contours.count;
}

- (Contour *)objectAtIndexedSubscript:(NSInteger)idx {
    return self.contours[idx];
}

#pragma MARK -

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

- (UIImage *)render:(BOOL (^)(Contour *c))filter {
    return [self render:[UIColor whiteColor] mode:ContourRenderingModeOutline filtered:filter];
}

- (UIImage *)render:(UIColor *)color mode:(ContourRenderingMode)mode filtered:(BOOL (^)(Contour *c))filter {
    cv::Mat outImage = cv::Mat::zeros(self.image.size.height, self.image.size.width, CV_8UC4);

    cv::Scalar contourColor = [self scalarColorFrom:color];
    std::vector<std::vector<cv::Point> > contours;

    for (int i = 0; i < self.contours.count; i++){
        Contour *contour = self.contours[i];
        if (filter) if (!filter(contour)) continue;
        contours.push_back(contour.mat);
    }

    switch (mode) {
        case ContourRenderingModeOutline:
            cv::drawContours(outImage, contours, -1, contourColor, 1);
            break;
        case ContourRenderingModeFill:
            cv::drawContours(outImage, contours, -1, contourColor, -1);
            break;
    }

    return [[UIImage alloc] initWithCVMat:outImage];
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
/**
 CGRect bounds = contour.bounds;
 cv::Point p1 = cv::Point(bounds.origin.x, contour.bounds.origin.y);
 cv::Point p2 = cv::Point(p1.x + contour.bounds.size.width, p1.y + contour.bounds.size.height);
 cv::rectangle(outImage, p1, p2, color);
*/
