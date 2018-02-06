#import <UIKit/UIKit.h>

@class UIImageContours;
@interface UIImage (OpenCV)
- (UIImage *)resizeTo:(CGSize)minSize;
- (UIImage *)rectangle;

- (UIImage *)threshold:(float)blockSize constant:(float)constant;
- (UIImage *)dilate:(CGSize)kernelSize;
- (UIImage *)erode:(CGSize)kernelSize;

- (UIImage *)elementwiseMinimum:(UIImage *)img;

- (UIImageContours *)contours;

@end

