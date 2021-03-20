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

    float scl = MAX(scl_x, scl_y);

    float inv_scl = 1.0;
    if (scl > 1.0) {
        inv_scl = 1.0/scl;
        cv::resize(inImage, outImage, axis, inv_scl, inv_scl, cv::INTER_AREA);
    } else {
        outImage = inImage;
    }

    return [[UIImage alloc] initWithCVMat: outImage];
}

- (UIImage *)gray {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;
    cv::cvtColor(inImage, outImage, cv::COLOR_RGBA2GRAY);
    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)canny:(double)threshold1 threshold2:(double)threshold2 {
    cv::Mat inImage = [self mat];
    cv::Mat canny;
    cv::Canny(inImage, canny, threshold1, threshold2);
    return [[UIImage alloc] initWithCVMat:canny];
}

- (UIImage *)blur:(CGSize)size sigmaX:(double)sigmaX {
    cv::Mat inImage = [self mat];
    cv::Mat blurred;
    cv::GaussianBlur(inImage, blurred, cv::Size(size.width, size.height), sigmaX);
    return [[UIImage alloc] initWithCVMat:blurred];
}

- (UIImage *)invert {
    cv::Mat inImage = [self mat];
    cv::Mat outImage;
    cv::bitwise_not(inImage, outImage);
    return [[UIImage alloc] initWithCVMat:outImage];
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

- (UIImage *)rectangle:(CGRectOutline)outline {
    int width = self.size.width;
    int height = self.size.height;
    cv::Mat r = cv::Mat::zeros(height, width, CV_8UC4);

    cv::Point tl = cv::Point(outline.topLeft.x, outline.topLeft.y);
    cv::Point br = cv::Point(outline.botRight.x, outline.botRight.y);
    cv::rectangle(r, tl, br, cv::Scalar(255, 255, 255), -1);
    return [[UIImage alloc] initWithCVMat: r];
}

- (UIImage *)subImage:(CGRect)bounds {
    cv::Mat inImage = [self mat];
    cv::Rect rect = cv::Rect(bounds.origin.x,
                             bounds.origin.y,
                             bounds.size.width,
                             bounds.size.height);
    cv::Mat outImage = inImage(rect).clone();
    return [[UIImage alloc] initWithCVMat:outImage];
}

- (UIImage *)renderRect:(CGRect)rect borderColor:(UIColor *)borderColor {
    return [self renderRect:rect borderColor:borderColor borderWidth: 1.0];
}

- (UIImage *)renderRect:(CGRect)rect borderColor:(UIColor *)borderColor borderWidth:(NSInteger)borderWidth {
    return [self renderRect:rect borderColor:borderColor borderWidth: 1.0 fillColor: NULL];
}

- (UIImage *)renderRect:(CGRect)rect borderColor:(UIColor *)borderColor borderWidth:(NSInteger)borderWidth fillColor:(UIColor *)fillColor {
    cv::Mat inImage = [self mat];
    cv::Rect roi = cv::Rect(rect.origin.x, rect.origin.y,
                            rect.size.width, rect.size.height);

    // fill
    if (fillColor) {
        const CGFloat *components = CGColorGetComponents(fillColor.CGColor);
        CGFloat alpha = components[3];
        cv::Scalar fill = [self scalarColorFrom:fillColor];
        cv::Mat rectangle;
        inImage.copyTo(rectangle);
        cv::rectangle(rectangle, roi, fill, -1);
        cv::addWeighted(rectangle, alpha, inImage, 1.0 - alpha, 0, inImage);
    }

    // border
    cv::Scalar border = [self scalarColorFrom:borderColor];
    cv::rectangle(inImage, roi, border, (int)borderWidth, cv::LINE_AA);

    return [[UIImage alloc] initWithCVMat:inImage];
}

- (UIImage *)extractTextContents {
    cv::Mat inImage = [self mat];

    // Transform source image to gray if it is not
    cv::Mat gray;
    if (inImage.channels() == 3) {
        cv::cvtColor(inImage, gray, cv::COLOR_RGB2GRAY);
    } else if (inImage.channels() == 4) {
        cv::cvtColor(inImage, gray, cv::COLOR_RGBA2GRAY);
    } else {
        gray = inImage;
    }

    cv::Mat bw;
    cv::adaptiveThreshold(gray, bw, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 7, 7);

    cv::Mat bwClone = bw.clone();
    cv::Mat structure = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(16,4));
    cv::erode(bwClone, bwClone, structure, cv::Point(1, 1));

    cv::Mat structure2 = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(10,10));
    cv::dilate(bwClone, bwClone, structure2, cv::Point(-1, -1));

    cv::erode(bwClone, bwClone, structure, cv::Point(1, 1));
    cv::bitwise_not(bwClone, bwClone);

    cv::Mat structure3 = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(8,8));
    cv::dilate(bwClone, bwClone, structure3, cv::Point(-1, -1));

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(bwClone, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);

    double largestContour = -1000000;
    int indexOfContour = -1;
    for (int i = 0; i < contours.size(); i++) {
        std::vector<cv::Point> contour = contours[i];
        double contourArea = fabs(cv::contourArea(cv::Mat(contour)));
        if (contourArea > largestContour) {
            largestContour = contourArea;
            indexOfContour = i;
        }
    }

    cv::Scalar black = cv::Scalar(255, 255, 255);
    cv::Mat contourMask = cv::Mat(bwClone.rows, bwClone.cols, CV_8UC1);
    cv::drawContours(contourMask, contours, indexOfContour, black, -1);
    //UIImage *contoursImage = [[UIImage alloc] initWithCVMat:contourMask];

    cv::Mat outImage = inImage.clone();
    outImage.setTo(black);
    //UIImage *outOutImage = [[UIImage alloc] initWithCVMat:outImage];

    inImage.copyTo(outImage, contourMask);
    //UIImage *outImageImage = [[UIImage alloc] initWithCVMat:outImage];

    return [[UIImage alloc] initWithCVMat:outImage];
}

// MARK: - Render helpers
- (cv::Scalar)scalarColorFrom:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return cv::Scalar(red * 255.0, green * 255.0, blue * 255.0, alpha * 255.0);
}

@end
