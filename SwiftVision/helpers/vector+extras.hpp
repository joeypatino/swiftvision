#ifndef vector_extras_hpp
#define vector_extras_hpp

#import <opencv2/opencv.hpp>
#include <vector>
#include <cassert>

using namespace std;
using namespace cv;

typedef std::vector<double> vector_d;
typedef std::vector<std::vector<double>> vector_dd;

namespace vectors {
    vector_dd hstack(vector_dd mat1, vector_dd mat2);
    vector_dd reshape(vector_d p, int rows, int cols);
    vector_dd reshape(vector_dd p, int rows, int cols);

    void meshgrid(vector_d x, vector_d y, vector_dd *xx, vector_dd *yy);
    
    vector<double> axis(int x, vector<Point2d> points);
    vector<vector<double>> convert_to_vector2d(vector<Point2d> points);

    std::vector<double> dotProduct(std::vector<cv::Point2d> points, cv::Point2d x);
    std::vector<double> subtract(std::vector<double> b, double x);
    std::vector<cv::Point2d> add(std::vector<cv::Point2d> points, cv::Point2f pt);
    std::vector<cv::Point2d> multi(std::vector<cv::Point2d> points, float scale);

    std::vector<cv::Point2d> pix2norm(cv::Size2d size, std::vector<cv::Point2d> points);
    std::vector<cv::Point2d> norm2pix(cv::Size2d size, std::vector<cv::Point2d> points);
}

#endif /* vector_extras_hpp */
