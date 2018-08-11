#import <opencv2/opencv.hpp>
#import "PageDetector.h"
// extras
#import "UIImage+Mat.h"
#import "vectors.hpp"

using namespace std;
using namespace cv;

@interface PageDetector()
@end

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

    // and copy the magic apple
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
    cv::Mat blurred, gray, dialate1, dialate2, canny;

    cv::cvtColor(inImage, gray, cv::COLOR_RGBA2GRAY);
    cv::medianBlur(gray, blurred, 21);

    cv::Mat dialateKernel1 = cv::Mat::ones(21, 21, CV_8UC1);
    cv::dilate(blurred, dialate1, dialateKernel1);

    cv::Canny(dialate1, canny, 1, 255, 3);

    cv::Mat dialateKernel2 = cv::Mat::ones(8, 8, CV_8UC1);
    cv::dilate(canny, dialate2, dialateKernel2);

    cv::Mat structure = cv::getStructuringElement(MORPH_RECT, cv::Size(5, 5));
    cv::morphologyEx(dialate2, outImage, MORPH_CLOSE, structure);

    return outImage;
}

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

/** finds the boundary points of the largest contour in inImage.
 * inImage must be a grayscale image, already preprocessed for edge
 * detection. */
- (std::vector<std::vector<cv::Point2d>>)findPageBounds:(cv::Mat)inImage {
    double imageArea = inImage.cols * inImage.rows;
    std::vector<std::vector<cv::Point2d>> squares;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Point> approx;

    // Find contours, store them in a list and test each
    cv::findContours(inImage, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
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
            cv::isContourConvex(cv::Mat(approx)) &&
            contourArea > imageArea * 0.35 &&
            contourArea < imageArea * 0.8) {

            double maxCosine = 0;
            for (int j = 2; j < 5; j++) {
                double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                maxCosine = MAX(maxCosine, cosine);
            }

            if (maxCosine < 0.3) {
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

@end
