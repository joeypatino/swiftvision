#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

@interface UIImage (OpenCV)
- (instancetype)initWithCVMat:(cv::Mat)cvMat;
- (cv::Mat)mat;
- (cv::Mat)matGray;
- (UIImage *)resizeTo:(CGSize)minSize;

@end
