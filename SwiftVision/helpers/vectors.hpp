#ifndef dewarp_vectors_hpp
#define dewarp_vectors_hpp

#import <opencv2/opencv.hpp>

namespace vectors {
    std::vector<double> linspace(double a, double b, double N);
    std::vector<cv::Point2d> norm2pix(cv::Size2d size, std::vector<cv::Point2d> points);
    std::vector<cv::Point2d> pix2norm(cv::Size2d size, std::vector<cv::Point2d> points);
}

#endif /* dewarp_vectors_hpp */
