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

    /// subtracts p2 from p1 eg... (p1 - p2)
    CGPoint subtract(CGPoint p1, CGPoint p2);
    /// subtracts d from p
    cv::Point2f subtract(CGPoint p, float d);

    /// sums the x and y values in the point p
    float sum(cv::Point2f p);

    /// performs multiplication Point2f objects..
    cv::Point2f multi(cv::Point2f p1, cv::Point2f p2);
    cv::Point2f multi(cv::Point2f p, float x);

    // converts between CGPoint <-> Point2f
    CGPoint convertTo(cv::Point2f point);
    cv::Point2f convertTo(CGPoint point);

    // returns a CGRectOutline struct from size
    CGRectOutline outlineWithSize(CGSize size);
}

namespace nsarray {
    /// Adds pt to each point in points and returns the modified points
    NSArray <NSValue *> * add(NSArray <NSValue *> *points, cv::Point2f pt);

    /// subtracts value from all values and returns modified values
    NSArray <NSNumber *> * subtract(NSArray <NSNumber *> *values, float value);

    /// multiplies each pt in points by scale and returns modified points
    NSArray <NSValue *> * multi(NSArray <NSValue *> *points, float scale);

    /// Calculates the dot proudct of an array of points and a single point, mimics the numpy method `np.dot(a, b)`
    NSArray <NSNumber *> * dotProduct(NSArray <NSValue *> *points, cv::Point2f pt);

    NSArray <NSValue *> * pix2norm(CGSize size, NSArray <NSValue *> *points);
    NSArray <NSValue *> * norm2pix(CGSize size, NSArray <NSValue *> *points);

    std::vector<cv::Point2f> convertTo(NSArray <NSValue *> *points);
    NSArray <NSValue *> * pointsFrom(CGRectOutline cornerOutline);
}

namespace logs {
    void describe_vector(std::vector<double> vector, char const *name);
    void describe_vector(std::vector<cv::Point> vector, char const *name);
    void describe_vector(std::vector<cv::Point2f> vector, char const *name);
    void describe_vector(std::vector<cv::Point3f> vector, char const *name);
    void describe_vector(std::vector<std::vector<int>> vector, char const *name);
    void describe_vector(cv::Mat mat, char const *name);

    void describe_values(NSArray <NSNumber *> *pts, char const *name);
    void describe_points(NSArray <NSValue *> *pts, char const *name);
}
