#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

@interface UIImage (OpenCV)
/**
 @param blockSize Size of a pixel neighborhood that is used to calculate a threshold value for the pixel: 3, 5, 7, and so on.
 @param constant Constant subtracted from the mean or weighted mean. Normally, it is positive but may be zero or negative as well.
 */
- (UIImage *_Nullable)gray;
- (UIImage *_Nullable)invert;
- (UIImage *_Nullable)threshold:(float)blockSize constant:(float)constant;
- (UIImage *_Nullable)dilate:(CGSize)kernelSize;
- (UIImage *_Nullable)erode:(CGSize)kernelSize;
- (UIImage *_Nullable)elementwiseMinimum:(UIImage *_Nonnull)img;
- (UIImage *_Nullable)resizeTo:(CGSize)minSize;
- (UIImage *_Nullable)rectangle:(CGRectOutline)outline;
- (UIImage *_Nullable)subImage:(CGRect)bounds;

@end
