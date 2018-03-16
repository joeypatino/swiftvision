#ifndef print_extras_hpp
#define print_extras_hpp

#include <stdio.h>
#import <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

namespace logs {
    void describe_vector(std::vector<std::vector<double>> vector, char const *name);
    void describe_vector(std::vector<double> vector, char const *name);
    void describe_vector(std::vector<float> vector, char const *name);
    void describe_vector(std::vector<cv::Point> vector, char const *name);
    void describe_vector(std::vector<cv::Point2d> vector, char const *name);
    void describe_vector(std::vector<cv::Point2f> vector, char const *name);
    void describe_vector(std::vector<cv::Point3d> vector, char const *name);
    void describe_vector(std::vector<cv::Point3f> vector, char const *name);
    void describe_vector(cv::Mat mat, char const *name);
}

#endif /* print_extras_hpp */

