#import <opencv2/opencv.hpp>
#import "UIImage+OpenCV.h"
// extras
#import "UIImage+Mat.h"
#import "CGRectOutline.h"

@implementation UIImage (OpenCV)
- (UIImage *)resizeTo:(CGSize)size {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;
    cv::Size axis = cv::Size(0, 0);

    float height = self.size.height;
    float width = self.size.width;
    float scl_x = width / size.width;
    float scl_y = height / size.height;

    int scl = int(ceil(MAX(scl_x, scl_y)));

    float inv_scl = 1.0;
    if (scl > 1.0) {
        inv_scl = 1.0/scl;
        cv::resize(inImage, outImage, axis, inv_scl, inv_scl, cv::INTER_AREA);
    } else {
        outImage = inImage;
    }

    return [[UIImage alloc] initWithCVMat: outImage];
}

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
    return [[UIImage alloc] initWithCVMat:expr];
}

- (UIImage *_Nullable)rectangle:(CGRectOutline)outline {
    int width = self.size.width;
    int height = self.size.height;
    cv::Mat r = cv::Mat::zeros(height, width, cv::DataType<int>::type);

    cv::Point tl = cv::Point(outline.topLeft.x, outline.topLeft.y);
    cv::Point br = cv::Point(outline.botRight.x, outline.botRight.y);
    cv::rectangle(r, tl, br, cv::Scalar(255, 255, 255), -1);
    return [[UIImage alloc] initWithCVMat: r];
}

@end
