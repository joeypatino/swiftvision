#import <opencv2/opencv.hpp>
#import "UIImage+OpenCV.h"
#import "UIImage+Mat.h"
#import "UIImageContours.h"

@interface Contour ()
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype)initWithCVMat:(cv::Mat)cvMat;
@end

@interface UIImageContours ()
- (instancetype _Nonnull)initWithContours:(NSArray <Contour *> *_Nonnull)contours inImage:(UIImage *_Nonnull)image NS_DESIGNATED_INITIALIZER;
@end

@implementation UIImage (OpenCV)
- (UIImage *)resizeTo:(CGSize)size {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;
    cv::Size axis = cv::Size(0, 0);

    float scl_x = float(self.size.width) / size.width;
    float scl_y = float(self.size.height) / size.height;
    float scl = 1.0 / fmaxf(scl_x, scl_y);

    cv::resize(inImage, outImage, axis, scl, scl, cv::INTER_AREA);

    return [[UIImage alloc] initWithCVMat: outImage];
}

- (UIImage *)rectangle {
    CGSize size = self.size;

    CGRectOutline outline = [self outline];
    cv::Point p1 = cv::Point(outline.topLeft.x, outline.topLeft.y);
    cv::Point p2 = cv::Point(outline.botRight.x, outline.botRight.y);

    cv::Mat page = cv::Mat(int(size.height), int(size.width), CV_8UC1);
    cv::rectangle(page, p1, p2, cv::Scalar(255.0, 255.0, 255.0), -1);

    return [[UIImage alloc] initWithCVMat: page];
}

- (CGRectOutline)outline {
    CGSize size = self.size;

    #define PAGE_MARGIN_X 0
    #define PAGE_MARGIN_Y 0

    int xmin = PAGE_MARGIN_X;
    int ymin = PAGE_MARGIN_Y;
    int xmax = int(size.width) - PAGE_MARGIN_X;
    int ymax = int(size.height) - PAGE_MARGIN_Y;

    return CGRectOutlineMake(CGPointMake(xmin, ymin),
                             CGPointMake(xmin, ymax),
                             CGPointMake(xmax, ymax),
                             CGPointMake(xmax, ymin));
}

/**
 @param blockSize Size of a pixel neighborhood that is used to calculate a threshold value for the
 pixel: 3, 5, 7, and so on.
 @param constant Constant subtracted from the mean or weighted mean (see the details below). Normally, it
 is positive but may be zero or negative as well.
 */
- (UIImage *)threshold:(float)blockSize constant:(float)constant {
    cv::Mat inImage = [self mat];
    cv::Mat grayImage;
    cv::Mat outImage;

    // convert to GRAYSCALE
    cv::cvtColor(inImage, grayImage, cv::COLOR_RGBA2GRAY);
    cv::adaptiveThreshold(grayImage, outImage,
                          255.0,
                          cv::ADAPTIVE_THRESH_MEAN_C,
                          cv::THRESH_BINARY_INV, blockSize, constant);

    // revert to RGBA
    cv::cvtColor(outImage, outImage, cv::COLOR_GRAY2RGBA);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)dilate:(CGSize)kernelSize {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;

    cv::Mat dilateKernel = cv::Mat::ones(kernelSize.height, kernelSize.width, CV_8UC1);
    cv::dilate(inImage, outImage, dilateKernel);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)erode:(CGSize)kernelSize {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;

    cv::Mat erodeKernel = cv::Mat::ones(kernelSize.height, kernelSize.width, CV_8UC1);
    cv::erode(inImage, outImage, erodeKernel);

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)elementwiseMinimum:(UIImage *)img {
    cv::Mat inImage = [self mat];
    cv::Mat compImage = [img mat];

    cv::MatExpr expr = cv::min(inImage, compImage);
    cv::Mat outImage = cv::Mat(expr);

    return [[UIImage alloc] initWithCVMat:outImage];
}

// MARK: -
- (UIImageContours *)contoursFilteredBy:(BOOL (^)(Contour * c))filter {
    NSArray <Contour *> *contours = [self generateContoursFilteredBy:filter];
    return [[UIImageContours alloc] initWithContours:contours inImage:self];
}

- (NSArray<Contour *> *)generateContoursFilteredBy:(BOOL (^)(Contour *c))filter {
    cv::Mat cvMat = [self grayScaleMat];
    NSMutableArray <Contour *> *foundContours = @[].mutableCopy;
    std::vector<std::vector<cv::Point> > contours;
    cv::findContours(cvMat, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);

    for (int j = 0; j < contours.size(); j++) {
        std::vector<cv::Point> points = contours.at(j);
        cv::Mat contourMat = cv::Mat(points);
        if (cv::contourArea(contourMat) == 0) continue;

        Contour *contour = [[Contour alloc] initWithCVMat:contourMat];
        if (filter)
            if (!filter(contour))
                continue;

        [foundContours addObject:contour];
    }

    return foundContours;
}

@end

