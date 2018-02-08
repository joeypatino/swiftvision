#import <UIKit/UIKit.h>

@class UIImageContours;
@interface UIImage (OpenCV)
- (UIImage *_Nullable)elementwiseMinimum:(UIImage * _Nonnull)img;
- (UIImage *_Nullable)resizeTo:(CGSize)minSize;
- (UIImage *_Nullable)rectangle;

- (UIImage *_Nullable)threshold:(float)blockSize constant:(float)constant;
- (UIImage *_Nullable)dilate:(CGSize)kernelSize;
- (UIImage *_Nullable)erode:(CGSize)kernelSize;

- (UIImageContours *_Nonnull)contours;

@end
