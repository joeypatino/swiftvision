#import <opencv2/opencv.hpp>
#import "PageDetector.h"
// extras
#import "UIImage+Mat.h"

using namespace std;
using namespace cv;

@implementation PageDetector

- (CGRectOutline)detectPage:(UIImage *)image {
    cv::Mat inImage = [image mat];
    std::vector<std::vector<cv::Point>> points = [self findSquaresIn:inImage];

    int largestArea = -1;
    CGRectOutline detectedOutline = CGRectOutlineMake(CGPointZero, CGPointZero, CGPointZero, CGPointZero);
    for (int i = 0; i < points.size(); i++) {
        std::vector<cv::Point> row = points.at(i);
        double area = fabs(cv::contourArea(row));
        double inPoly = cv::pointPolygonTest(cv::Mat(row), cv::Point(inImage.cols/2, inImage.rows/2), false);
        if (((area > largestArea) && (inPoly > 0)) || area == -1) {
            CGPoint topLeft = CGPointMake(row[0].x, row[0].y);
            CGPoint topRight = CGPointMake(row[3].x, row[3].y);
            CGPoint botRight = CGPointMake(row[2].x, row[2].y);
            CGPoint botLeft = CGPointMake(row[1].x, row[1].y);
            detectedOutline = CGRectOutlineMake(topLeft, topRight, botRight, botLeft);
            largestArea = area;
        }
    }

    return detectedOutline;
}

- (UIImage *)debug:(UIImage *)image {
    cv::Mat inImage = [image mat];
    CGRectOutline outline = [self detectPage:image];
    if (CGPointEqualToPoint(CGPointZero, outline.topLeft) &&
        CGPointEqualToPoint(CGPointZero, outline.topRight) &&
        CGPointEqualToPoint(CGPointZero, outline.botLeft) &&
        CGPointEqualToPoint(CGPointZero, outline.botRight))
        return [[UIImage alloc] initWithCVMat:inImage];

    std::vector<std::vector<cv::Point>> outlines;
    cv::Point topLeft = cv::Point(outline.topLeft.x, outline.topLeft.y);
    cv::Point topRight = cv::Point(outline.topRight.x, outline.topRight.y);
    cv::Point botRight = cv::Point(outline.botRight.x, outline.botRight.y);
    cv::Point botLeft = cv::Point(outline.botLeft.x, outline.botLeft.y);
    outlines.push_back({ topLeft, botLeft, botRight, topRight });
    [self renderSquares:outlines in:inImage];

    return [[UIImage alloc] initWithCVMat:inImage];
}

- (std::vector<std::vector<cv::Point>>)findSquaresIn:(cv::Mat)inImage {
    std::vector<std::vector<cv::Point>> squares;

    cv::Mat image = inImage.clone();
    // blur will enhance edge detection
    cv::Mat blurred(image);
    cv::GaussianBlur(image, blurred, cv::Size(3,3), 0.02);
    cv::Mat gray0(blurred.size(), CV_8U), gray;
    std::vector<std::vector<cv::Point> > contours;

    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++) {
        int ch[] = {c, 0};
        cv::mixChannels(&blurred, 1, &gray0, 1, ch, 1);

        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++) {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0) {
                cv::Canny(gray0, gray, 0, 84, 3);

                // Dilate helps to remove potential holes between edge segments
                cv::dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            }
            else {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }

            // Find contours and store them in a list
            cv::findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);

            // Test contours
            std::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++) {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                cv::approxPolyDP(Mat(contours[i]), approx, cv::arcLength(cv::Mat(contours[i]), true)*0.02, true);

                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(cv::contourArea(cv::Mat(approx))) > 1000 &&
                    fabs(cv::contourArea(cv::Mat(approx))) < ((inImage.cols * inImage.rows) * 0.8) &&
                    cv::isContourConvex(cv::Mat(approx))) {

                    double maxCosine = 0;
                    for (int j = 2; j < 5; j++) {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }

                    if (maxCosine < 0.3)
                        squares.push_back(approx);
                }
            }
        }
    }
    return squares;
}

- (void)renderSquares:(std::vector<std::vector<cv::Point>>)squares in:(cv::Mat)mat {
    for ( int i = 0; i< squares.size(); i++ ) {
        // draw contour
        cv::drawContours(mat, squares, i, cv::Scalar(255,0,0), 1, LINE_AA);

//        // draw bounding rect
//        cv::Rect rect = boundingRect(cv::Mat(squares[i]));
//        cv::rectangle(mat, rect.tl(), rect.br(), cv::Scalar(0,255,0));
//
//        // draw rotated rect
//        cv::RotatedRect minRect = minAreaRect(cv::Mat(squares[i]));
//        cv::Point2f rect_points[4];
//        minRect.points( rect_points );
//        for ( int j = 0; j < 4; j++ ) {
//            cv::line( mat, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,0,255));
//        }
    }
}

double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

@end
