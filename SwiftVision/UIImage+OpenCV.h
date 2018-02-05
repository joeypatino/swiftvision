#import <UIKit/UIKit.h>

@interface UIImage (OpenCV)
- (cv::Mat)mat;
- (cv::Mat)matGray;

@end
