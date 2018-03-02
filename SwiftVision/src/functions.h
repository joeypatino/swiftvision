#ifndef functions_h
#define functions_h

#include <stdio.h>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

#endif /* functions_h */

namespace geom {
    double angleDistance(double angle_b, double angle_a);
    double intervalOverlap(CGPoint int_a, CGPoint int_b);
}

namespace geom {
    CGPoint subtract(CGPoint p1, CGPoint p2);
    cv::Point2f subtract(CGPoint p, float d);
    cv::Point2f multi(cv::Point2f p1, cv::Point2f p2);
    cv::Point2f multi(cv::Point2f p1, float v);
    CGPoint pointFrom(cv::Point2f point);
    CGRectOutline outlineWithSize(CGSize size);
    cv::Point2f pointFrom(CGPoint point);
    float sum(cv::Point2f p1);
}

namespace logs {
    void describe_vector(std::vector<double> vector, char const *name );
    void describe_vector(std::vector<cv::Point> vector, char const *name );
    void describe_vector(std::vector<cv::Point2f> vector, char const *name );
    void describe_vector( cv::Mat mat, char const *name );

    void describe_values(NSArray <NSNumber *> *pts, char const *name);
    void describe_points(NSArray <NSValue *> *pts, char const *name);
}

namespace nsarray {
    NSArray <NSNumber *> * subtract(NSArray <NSNumber *> *values, float value);
    NSArray <NSNumber *> * dotProduct(NSArray <NSValue *> *pts, cv::Point2f pt);

    NSArray <NSValue *> * add(NSArray <NSValue *> *values, cv::Point2f pt);
    NSArray <NSValue *> * multi(NSArray <NSValue *> *pts, float scale);
    NSArray <NSValue *> * pix2norm(CGSize size, NSArray <NSValue *> *pts);
    NSArray <NSValue *> * norm2pix(CGSize size, NSArray <NSValue *> *points, BOOL isInt);

    std::vector<cv::Point2f> convertToVector(NSArray <NSValue *> *points);
}

cv::Mat maskWithOutline(CGRectOutline outline);
