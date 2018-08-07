#ifndef debug_hpp
#define debug_hpp

#import <opencv2/opencv.hpp>
#include "DataTypes.h"

namespace debug {
    void describe_vector(std::vector<std::vector<double>> vector, char const *name);
    void describe_vector(std::vector<double> vector, char const *name);
    void describe_vector(std::vector<float> vector, char const *name);
    void describe_vector(std::vector<std::vector<DPoint>> vector, char const *name);
    void describe_vector(std::vector<DPoint> vector, char const *name);
    void describe_vector(std::vector<cv::Point> vector, char const *name);
    void describe_vector(std::vector<cv::Point2d> vector, char const *name);
    void describe_vector(std::vector<cv::Point2f> vector, char const *name);
    void describe_vector(std::vector<cv::Point3d> vector, char const *name);
    void describe_vector(std::vector<cv::Point3f> vector, char const *name);
    void describe_vector(cv::Mat mat, char const *name);
}

#endif /* debug_hpp */

