#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface UIImage (Mat)
+ (instancetype _Nullable)imageWithMat:(cv::Mat)mat;
- (instancetype _Nullable)initWithCVMat:(cv::Mat)cvMat;
- (cv::Mat)mat;
- (cv::Mat)grayScaleMat;
@end
