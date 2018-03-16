#import "KeyPointProjector.h"
#import "functions.h"

@implementation KeyPointTester
// Test methods...
//- (std::vector<cv::Point2f>)testprojectKeypoints:(std::vector<cv::Point2f>)keyPoints of:(std::vector<double>)vectors {
//    std::vector<cv::Point2f> xy_coords = {
//        cv::Point2f(0.00000000,0.00000000),
//        cv::Point2f(0.20033272,0.07952788),
//        cv::Point2f(0.25980987,0.07952788),
//        cv::Point2f(0.31932692,0.07952788),
//        cv::Point2f(0.37862638,0.07952788),
//        cv::Point2f(0.43772273,0.07952788),
//        cv::Point2f(0.61108224,0.10414961),
//        cv::Point2f(0.39245898,0.22384480)
//    };
//    std::vector<double> pvec = {-0.00000000,0.00000000,0.01341045,-0.74919273,-1.01938189,1.79999995,0.00000000,0.00000000};
//    return [self projectXY:xy_coords of:pvec];
//}
//
//- (std::vector<cv::Point2f>)testprojectXY:(std::vector<cv::Point2f>)xyCoordsArr of:(std::vector<double>)vectors {
//    std::vector<cv::Point3f> objectPoints = {
//        cv::Point3f(0.00000000,0.00000000,0.00000000),
//        cv::Point3f(0.20033272,0.07952788,0.00000000),
//        cv::Point3f(0.25980987,0.07952788,0.00000000),
//        cv::Point3f(0.31932692,0.07952788,0.00000000)
//    };
//    std::vector<double> rvec = {-0.00000000,0.00000000,0.01341045};
//    std::vector<double> tvec = {-0.74919273,-1.01938189,1.79999995};
//    cv::Mat intrinsics = [self cameraIntrinsics];
//    cv::Mat distanceCoeffs = cv::Mat::zeros(1, 5, CV_64FC1);
//
//    std::vector<cv::Point2f> imagePoints;
//    projectPoints(objectPoints, rvec, tvec, intrinsics, distanceCoeffs, imagePoints);
//    logs::describe_vector(imagePoints, "imagePoints");
//
//    // expected output
//    //[[-0.74919273 -1.01938189]]
//    //[[-0.54994450 -0.93717469]]
//    //[[-0.49047270 -0.93637710]]
//    //[[-0.43096100 -0.93557897]]
//
//    // actual output
//    //[-0.74919277, -1.0193819;
//    // -0.54994452, -0.93717474;
//    // -0.4904727, -0.93637711;
//    // -0.43096101, -0.935579]
//
//    return imagePoints;
//}
@end
