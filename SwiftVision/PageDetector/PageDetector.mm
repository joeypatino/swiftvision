#import <opencv2/opencv.hpp>
#import "PageDetector.h"
// extras
#import "UIImage+Mat.h"
#import "vectors.hpp"

using namespace std;
using namespace cv;

@implementation PageDetector

- (CGRectOutline)pageBounds:(UIImage *)image {
    cv::Mat inImage = [self preprocessImage:image];
    std::vector<std::vector<cv::Point2d>> points = [self findPageBounds:inImage];
    int largestArea = -1;
    cv::Point center = cv::Point2d(inImage.cols/2, inImage.rows/2);
    CGRectOutline detectedOutline = CGRectOutlineZeroMake();
    for (int i = 0; i < points.size(); i++) {
        std::vector<cv::Point2d> row = points.at(i);
        std::vector<cv::Point> row2i;
        for (int i = 0; i < row.size(); i++) {
            row2i.push_back(cv::Point(row[i].x, row[i].y));
        }
        double area = fabs(cv::contourArea(row2i));
        double inPoly = cv::pointPolygonTest(row2i, center, false);

        row = vectors::pix2norm(cv::Size(image.size.width, image.size.height), row);
        if (((area > largestArea) && (inPoly > 0)) || area == -1) {
            CGPoint topLeft = CGPointMake(row[0].x, row[0].y);
            CGPoint topRight = CGPointMake(row[1].x, row[1].y);
            CGPoint botRight = CGPointMake(row[2].x, row[2].y);
            CGPoint botLeft = CGPointMake(row[3].x, row[3].y);
            detectedOutline = CGRectOutlineMake(topLeft, topRight, botRight, botLeft);
            largestArea = area;
        }
    }

    return detectedOutline;
}

- (UIImage *)extractPage:(UIImage *)image {
    CGRectOutline outline = [self pageBounds:image];
    if (CGRectOutlineEquals(outline, CGRectOutlineZeroMake()))
        return image;

    return [self extract:outline fromImage:image];
}

- (UIImage *)extract:(CGRectOutline)outline fromImage:(UIImage *)image {
    std::vector<std::vector<cv::Point2d>> normOutlines = [self contoursFromOutline:outline];
    std::vector<std::vector<cv::Point2d>> outlines;
    std::vector<std::vector<cv::Point>> outlinesI;
    for (int i = 0; i < normOutlines.size(); i++) {
        std::vector<cv::Point2d> pts = normOutlines[i];
        outlines.push_back(vectors::norm2pix(cv::Size(image.size.width, image.size.height), pts));
    }
    for (int i = 0; i < outlines.size(); i++) {
        std::vector<cv::Point2d> pts = outlines[i];
        std::vector<cv::Point> pt;
        for (int j = 0; j < pts.size(); j++) {
            cv::Point2d ptd = pts[j];
            pt.push_back(cv::Point(ptd.x, ptd.y));
        }
        outlinesI.push_back(pt);
    }

    cv::Mat inImage = [image mat];
    cv::Mat mask = cv::Mat::zeros(inImage.rows, inImage.cols, CV_8UC1);

    // CV_FILLED fills the connected components found
    cv::drawContours(mask, outlinesI, -1, cv::Scalar(255), CV_FILLED, LINE_AA);

    // let's create a new image now
    cv::Mat crop(inImage.rows, inImage.cols, CV_8UC4);

    // set background to white
    crop.setTo(cv::Scalar(255, 255, 255, 255));

    // and copy the masked component
    inImage.copyTo(crop, mask);

    return [[UIImage alloc] initWithCVMat:crop];
}

- (UIImage *)renderPageBounds:(UIImage *)image {
    CGRectOutline outline = [self pageBounds:image];
    if (CGRectOutlineEquals(outline, CGRectOutlineZeroMake())) {
        return image;
    }
    cv::Mat inImage = [image mat];
    std::vector<std::vector<cv::Point2d>> normOutlines = [self contoursFromOutline:outline];
    std::vector<std::vector<cv::Point2d>> outlines;
    std::vector<std::vector<cv::Point>> outlinesI;
    for (int i = 0; i < normOutlines.size(); i++) {
        std::vector<cv::Point2d> pts = normOutlines[i];
        outlines.push_back(vectors::norm2pix(cv::Size(image.size.width, image.size.height), pts));
    }
    for (int i = 0; i < outlines.size(); i++) {
        std::vector<cv::Point2d> pts = outlines[i];
        std::vector<cv::Point> pt;
        for (int j = 0; j < pts.size(); j++) {
            cv::Point2d ptd = pts[j];
            pt.push_back(cv::Point(ptd.x, ptd.y));
        }
        outlinesI.push_back(pt);
    }
    cv::drawContours(inImage, outlinesI, -1, cv::Scalar(255,0,0), 1, LINE_AA);
    return [[UIImage alloc] initWithCVMat:inImage];
}

- (UIImage *)render:(CGRectOutline)outline inImage:(UIImage *)image {
    if (CGRectOutlineEquals(outline, CGRectOutlineZeroMake())) {
        return image;
    }
    cv::Mat inImage = [image mat];
    std::vector<std::vector<cv::Point2d>> normOutlines = [self contoursFromOutline:outline];
    std::vector<std::vector<cv::Point2d>> outlines;
    std::vector<std::vector<cv::Point>> outlinesI;
    for (int i = 0; i < normOutlines.size(); i++) {
        std::vector<cv::Point2d> pts = normOutlines[i];
        outlines.push_back(vectors::norm2pix(cv::Size(image.size.width, image.size.height), pts));
    }
    for (int i = 0; i < outlines.size(); i++) {
        std::vector<cv::Point2d> pts = outlines[i];
        std::vector<cv::Point> pt;
        for (int j = 0; j < pts.size(); j++) {
            cv::Point2d ptd = pts[j];
            pt.push_back(cv::Point(ptd.x, ptd.y));
        }
        outlinesI.push_back(pt);
    }
    cv::drawContours(inImage, outlinesI, -1, cv::Scalar(255,0,0), 1, LINE_AA);
    return [[UIImage alloc] initWithCVMat:inImage];
}

/** Preprocesses a UIImage for edge detection. */
- (cv::Mat)preprocessImage:(UIImage *)image {
    cv::Mat inImage = [image mat];
    cv::Mat outImage;

    cv::Mat gray;
    cv::cvtColor(inImage, gray, cv::COLOR_RGBA2GRAY);

    cv::Mat blurred;
    cv::GaussianBlur(gray, blurred, cv::Size(5, 5), 0);

    cv::Mat canny;
    cv::Canny(blurred, canny, 10, 20);

    cv::Mat dialate;
    cv::Mat dialateKernel = cv::Mat::ones(4, 4, CV_8UC1);
    cv::dilate(canny, dialate, dialateKernel);

    // output the final results
    outImage = dialate;
    return outImage;
}

- (UIImage *)process:(UIImage *)image {
    return [UIImage imageWithMat:[self preprocessImage:image]];
}

//- (UIImage *)gray:(UIImage *)image {
//    cv::Mat inImage = [image mat];
//    cv::Mat gray;
//    gray = [self _gray:inImage];
//    return [UIImage imageWithMat:gray];
//}
//
//- (UIImage *)blurred:(UIImage *)image {
//    cv::Mat inImage = [image mat];
//    cv::Mat gray, blurred;
//    gray = [self _gray:inImage];
//    blurred = [self _blurred:gray];
//    return [UIImage imageWithMat:blurred];
//}
//
//- (UIImage *)dialate1:(UIImage *)image {
//    cv::Mat inImage = [image mat];
//    cv::Mat gray, blurred, dialate1;
//    gray = [self _gray:inImage];
//    blurred = [self _blurred:gray];
//    dialate1 = [self _dialate1:blurred];
//    return [UIImage imageWithMat:dialate1];
//}
//
//- (UIImage *)threshhold:(UIImage *)image {
//    cv::Mat inImage = [image mat];
//    cv::Mat gray, blurred, dialate1, thresh;
//    gray = [self _gray:inImage];
//    blurred = [self _blurred:gray];
//    dialate1 = [self _dialate1:blurred];
//    thresh = [self _threshhold:dialate1];
//    return [UIImage imageWithMat:thresh];
//}
//
//- (UIImage *)canny:(UIImage *)image {
//    cv::Mat inImage = [image mat];
//    cv::Mat gray, blurred, dialate1, thresh, canny;
//    gray = [self _gray:inImage];
//    blurred = [self _blurred:gray];
//    dialate1 = [self _dialate1:blurred];
//    thresh = [self _threshhold:dialate1];
//    canny = [self _canny:thresh];
//    return [UIImage imageWithMat:canny];
//}
//
//- (UIImage *)dialate2:(UIImage *)image {
//    cv::Mat inImage = [image mat];
//    cv::Mat gray, blurred, dialate1, thresh, canny, dialate2;
//    gray = [self _gray:inImage];
//    blurred = [self _blurred:gray];
//    dialate1 = [self _dialate1:blurred];
//    thresh = [self _threshhold:dialate1];
//    canny = [self _canny:thresh];
//    dialate2 = [self _dialate2:canny];
//    return [UIImage imageWithMat:dialate2];
//}
//
//- (cv::Mat)_gray:(cv::Mat)inImage {
//    cv::Mat gray;
//    cv::cvtColor(inImage, gray, cv::COLOR_RGBA2GRAY);
//    return gray;
//}
//
//- (cv::Mat)_blurred:(cv::Mat)inImage {
//    cv::Mat blurred;
//    cv::GaussianBlur(inImage, blurred, cv::Size(9, 9), 0);
//    return blurred;
//}
//
//- (cv::Mat)_dialate1:(cv::Mat)inImage {
//    cv::Mat dialate1;
//    cv::Mat dialateKernel1 = cv::Mat::ones(14, 14, CV_8UC1);
//    cv::dilate(inImage, dialate1, dialateKernel1);
//    return dialate1;
//}
//
//- (cv::Mat)_threshhold:(cv::Mat)inImage {
//    cv::Mat thresh;
//    cv::adaptiveThreshold(inImage, thresh, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 11, 2);
//    return thresh;
//}
//
//- (cv::Mat)_canny:(cv::Mat)inImage {
//    cv::Mat canny;
//    cv::Canny(inImage, canny, 255, 255, 3);
//    return canny;
//}
//
//- (cv::Mat)_dialate2:(cv::Mat)inImage {
//    cv::Mat dialate;
//    cv::Mat dialateKernel = cv::Mat::ones(2, 2, CV_8UC1);
//    cv::dilate(inImage, dialate, dialateKernel);
//    return dialate;
//}
//
//- (cv::Mat)_morph:(cv::Mat)inImage {
//    int operation = MORPH_OPEN;
//    int morph_elem = MORPH_ELLIPSE;
//    int morph_size = 3;
//
//    cv::Mat element = cv::getStructuringElement(morph_elem,
//                                                cv::Size(2 * morph_size + 1, 2 * morph_size + 1),
//                                                cv::Point( morph_size, morph_size));
//
//    cv::Mat morphed;
//    cv::morphologyEx(inImage, morphed, operation, element);
//    return morphed;
//}

/** Converts a CGRectOutline into a 'outlines' vector. */
- (std::vector<std::vector<cv::Point2d>>)contoursFromOutline:(CGRectOutline)outline {
    std::vector<std::vector<cv::Point2d>> outlines;
    cv::Point2d topLeft = cv::Point2d(outline.topLeft.x, outline.topLeft.y);
    cv::Point2d topRight = cv::Point2d(outline.topRight.x, outline.topRight.y);
    cv::Point2d botRight = cv::Point2d(outline.botRight.x, outline.botRight.y);
    cv::Point2d botLeft = cv::Point2d(outline.botLeft.x, outline.botLeft.y);
    outlines.push_back({ topLeft, botLeft, botRight, topRight });
    return outlines;
}

- (CGRectOutline)norm2Pix:(CGRectOutline)outline size:(CGSize)size {
    if (CGRectOutlineEquals(outline, CGRectOutlineZeroMake()))
        return outline;
    outline.topLeft = normalizePoint(outline.topLeft, size);
    outline.topRight = normalizePoint(outline.topRight, size);
    outline.botRight = normalizePoint(outline.botRight, size);
    outline.botLeft = normalizePoint(outline.botLeft, size);
    return outline;
}

/** finds the boundary points of the largest contour in inImage.
 * inImage must be a grayscale image, already preprocessed for edge
 * detection. */
- (std::vector<std::vector<cv::Point2d>>)findPageBounds:(cv::Mat)inImage {
    double imageArea = inImage.cols * inImage.rows;
    std::vector<std::vector<cv::Point2d>> squares;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Point> approx;

    // Find contours, store them in a list and test each
    cv::findContours(inImage, contours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    for (size_t i = 0; i < contours.size(); i++) {
        // approximate contour with accuracy proportional
        // to the contour perimeter
        cv::approxPolyDP(Mat(contours[i]),
                         approx,
                         cv::arcLength(cv::Mat(contours[i]), true)*0.02,
                         true);

        // Note: absolute value of an area is used because
        // area may be positive or negative - in accordance with the
        // contour orientation
        double contourArea = fabs(cv::contourArea(cv::Mat(approx)));
        if (approx.size() == 4 &&
//            cv::isContourConvex(cv::Mat(approx)) &&
            contourArea > imageArea * 0.35 &&
            contourArea < imageArea * 0.8) {

            double maxCosine = 0;
            for (int j = 2; j < 5; j++) {
                double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                maxCosine = MAX(maxCosine, cosine);
            }

            if (maxCosine < 0.45) {
                std::vector<cv::Point2d> approxOut;
                for (int i = 0; i < approx.size(); i++) {
                    cv::Point p = approx[i];
                    approxOut.push_back(cv::Point2d(p.x, p.y));
                }
                squares.push_back(approxOut);
            }
        }
    }
    return squares;
}

double angle( cv::Point2d pt1, cv::Point2d pt2, cv::Point2d pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

CGPoint normalizePoint(CGPoint p, CGSize size) {
    float scale = MAX(size.height, size.width) * 0.5;
    CGPoint offset = CGPointMake(0.5 * size.width, 0.5 * size.height);
    return CGPointMake((p.x * scale) + offset.x, (p.y * scale) + offset.y);
}

@end
