#import <opencv2/opencv.hpp>
#import "PageDetector.h"
// extras
#import "UIImage+Mat.h"
#import "vectors.hpp"

using namespace std;
using namespace cv;

@implementation PageDetector

- (CGRectOutline)pageOutline:(UIImage *)image {
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
    CGRectOutline outline = [self pageOutline:image];
    if (CGRectOutlineEquals(outline, CGRectOutlineZeroMake()))
        return image;

    return [self extract:outline fromImage:image];
}

- (UIImage *)extract:(CGRectOutline)outline fromImage:(UIImage *)image {
    std::vector<std::vector<cv::Point2d>> normOutlines = [self contoursFromOutline:outline];

    UIImage *deskewed = [self deskew:image withOutline:outline];
    cv::Mat inImage = [deskewed mat];

    cv::Mat gray;
    cv::cvtColor(inImage, gray, cv::COLOR_RGBA2GRAY);

    cv::Mat thresh;
    cv::adaptiveThreshold(gray, thresh, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 3, 7);

    cv::Mat erode;
    cv::Mat erodeKernel = cv::Mat::ones(2, 2, CV_8UC1);
    cv::erode(thresh, erode, erodeKernel);

    cv::Mat outImage;
    cv::cvtColor(erode, outImage, cv::COLOR_GRAY2RGBA);

    return [UIImage imageWithMat:outImage];
}

- (UIImage *)renderPageOutline:(UIImage *)image {
    CGRectOutline outline = [self pageOutline:image];
    return [self render:outline inImage:image];
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
    cv::drawContours(inImage, outlinesI, -1, cv::Scalar(255,0,0), 10, LINE_AA);

    cv::circle(inImage, outlines[0][0], 70, cv::Scalar(255, 255, 255), -1);
    [self addLabel:"tl" toMat:inImage atPoint:outlines[0][0]];

    cv::circle(inImage, outlines[0][1], 70, cv::Scalar(255, 255, 255), -1);
    [self addLabel:"tr" toMat:inImage atPoint:outlines[0][1]];

    cv::circle(inImage, outlines[0][2], 70, cv::Scalar(255, 255, 255), -1);
    [self addLabel:"br" toMat:inImage atPoint:outlines[0][2]];

    cv::circle(inImage, outlines[0][3], 70, cv::Scalar(255, 255, 255), -1);
    [self addLabel:"bl" toMat:inImage atPoint:outlines[0][3]];

    return [[UIImage alloc] initWithCVMat:inImage];
}

- (void)addLabel:(cv::String)label toMat:(cv::Mat)mat atPoint:(cv::Point)p {

    int font = cv::FONT_HERSHEY_PLAIN;
    cv::Size s = cv::getTextSize(label, font, 6, 4, NULL);
    cv::putText(mat, label, cv::Point(p.x - s.width/2, p.y + s.height/2), font, 6,  cv::Scalar(255, 0, 0), 4);
}

- (UIImage *)process:(UIImage *)image {
    return [UIImage imageWithMat:[self preprocessImage:image]];
}

/** Converts a CGRectOutline into a 'outlines' vector. */
- (std::vector<std::vector<cv::Point2d>>)contoursFromOutline:(CGRectOutline)outline {
    std::vector<std::vector<cv::Point2d>> outlines;
    cv::Point2d topLeft = cv::Point2d(outline.topLeft.x, outline.topLeft.y);
    cv::Point2d topRight = cv::Point2d(outline.topRight.x, outline.topRight.y);
    cv::Point2d botRight = cv::Point2d(outline.botRight.x, outline.botRight.y);
    cv::Point2d botLeft = cv::Point2d(outline.botLeft.x, outline.botLeft.y);
    outlines.push_back({ topLeft, topRight, botRight, botLeft });
    return outlines;
}

- (CGRectOutline)denormalize:(CGRectOutline)outline withSize:(CGSize)size {
    if (CGRectOutlineEquals(outline, CGRectOutlineZeroMake()))
        return outline;
    outline.topLeft = denormalizePoint(outline.topLeft, size);
    outline.topRight = denormalizePoint(outline.topRight, size);
    outline.botRight = denormalizePoint(outline.botRight, size);
    outline.botLeft = denormalizePoint(outline.botLeft, size);
    return outline;
}

/** Preprocesses a UIImage for edge detection. */
- (cv::Mat)preprocessImage:(UIImage *)image {
    cv::Mat inImage = [image mat];
    cv::Mat outImage;

    cv::Mat gray;
    cv::cvtColor(inImage, gray, cv::COLOR_RGBA2GRAY);

    cv::Mat blurred;
    cv::GaussianBlur(gray, blurred, cv::Size(23, 23), 0);

    cv::Mat canny;
    cv::Canny(blurred, canny, 10, 20);

    cv::Mat dialate;
    cv::Mat dialateKernel = cv::Mat::ones(8, 8, CV_8UC1);
    cv::dilate(canny, dialate, dialateKernel);

    // output the final results
    outImage = dialate;
    return outImage;
}

- (UIImage *)deskew:(UIImage *)image withOutline:(CGRectOutline)outline {
    CGRectOutline normOutline = [self denormalize:outline withSize:image.size];
    cv::Mat inImage = [image mat];
    cv::Mat outImage;
    int widthA = sqrt(pow(normOutline.botRight.x - normOutline.botLeft.x, 2) + pow(normOutline.botRight.y - normOutline.botLeft.y, 2));
    int widthB = sqrt(pow(normOutline.topRight.x - normOutline.topLeft.x, 2) + pow(normOutline.topRight.y - normOutline.topLeft.y, 2));
    int maxWidth = max(widthA, widthB);

    int heightA = sqrt(pow(normOutline.topRight.x - normOutline.botRight.x, 2) + pow(normOutline.topRight.y - normOutline.botRight.y, 2));
    int heightB = sqrt(pow(normOutline.topLeft.x - normOutline.botLeft.x, 2) + pow(normOutline.topLeft.y - normOutline.botLeft.y, 2));
    int maxHeight = max(heightA, heightB);

    CGRectOutline destinationPoints = CGRectOutlineMake(CGPointZero,
                                                        CGPointMake(maxWidth - 1, 0),
                                                        CGPointMake(maxWidth - 1, maxHeight - 1),
                                                        CGPointMake(0, maxHeight - 1));

    std::vector<std::vector<cv::Point2d>> src = [self contoursFromOutline:normOutline];
    std::vector<std::vector<cv::Point2d>> dst = [self contoursFromOutline:destinationPoints];
    const cv::Point2f srcPts[] = { src[0][0], src[0][1], src[0][2], src[0][3] };
    const cv::Point2f dstPts[] = { dst[0][0], dst[0][1], dst[0][2], dst[0][3] };
    cv::Mat M = cv::getPerspectiveTransform(srcPts, dstPts);
    cv::warpPerspective(inImage, outImage, M, cv::Size(maxWidth, maxHeight));
    return [UIImage imageWithMat:outImage];
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
                         cv::arcLength(cv::Mat(contours[i]), true)*0.03,  // how square should this rect be?
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

CGPoint denormalizePoint(CGPoint p, CGSize size) {
    float scale = MAX(size.height, size.width) * 0.5;
    CGPoint offset = CGPointMake(0.5 * size.width, 0.5 * size.height);
    return CGPointMake((p.x * scale) + offset.x, (p.y * scale) + offset.y);
}

@end
