#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

@interface KeyPointProjector : NSObject
- (std::vector<cv::Point2f>)projectKeypoints:(std::vector<cv::Point2f>)keyPoints of:(double*)vectors;
@end
