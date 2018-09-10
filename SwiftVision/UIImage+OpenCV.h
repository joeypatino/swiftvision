#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

@interface UIImage (OpenCV)
- (UIImage *_Nullable)gray;
- (UIImage *_Nullable)invert;
/**
 @param blockSize Size of a pixel neighborhood that is used to calculate a threshold value for the pixel: 3, 5, 7, and so on.
 @param constant Constant subtracted from the mean or weighted mean. Normally, it is positive but may be zero or negative as well.
 */
- (UIImage *_Nullable)threshold:(float)blockSize constant:(float)constant;
- (UIImage *_Nullable)dilate:(CGSize)kernelSize;
- (UIImage *_Nullable)erode:(CGSize)kernelSize;
- (UIImage *_Nullable)blur:(CGSize)size sigmaX:(double)sigmaX;
- (UIImage *_Nullable)canny:(double)threshold1 threshold2:(double)threshold2;

- (UIImage *_Nullable)elementwiseMinimum:(UIImage *_Nonnull)img;
- (UIImage *_Nullable)resizeTo:(CGSize)minSize;
- (UIImage *_Nullable)rectangle:(CGRectOutline)outline;
- (UIImage *_Nullable)subImage:(CGRect)bounds;

- (UIImage *_Nullable)renderRect:(CGRect)rect borderColor:(UIColor *_Nonnull)borderColor;
- (UIImage *_Nullable)renderRect:(CGRect)rect borderColor:(UIColor *_Nonnull)borderColor borderWidth:(NSInteger)borderWidth;
- (UIImage *_Nullable)renderRect:(CGRect)rect borderColor:(UIColor *_Nonnull)borderColor borderWidth:(NSInteger)borderWidth fillColor:(UIColor *_Nullable)fillColor;

/**
 * attemps to isolate the text contents from the image. works by applying Morphological
 * transformations in order to determine the largest mass of pixels. The returned image is
 * then masked based on this result.
 */
- (UIImage *_Nullable)extractTextContents;

@end
