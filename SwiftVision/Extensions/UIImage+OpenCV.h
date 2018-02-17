#import <UIKit/UIKit.h>

@class UIImageContours;
@class Contour;
@interface UIImage (OpenCV)
- (UIImage *_Nullable)threshold:(float)blockSize constant:(float)constant;
- (UIImage *_Nullable)dilate:(CGSize)kernelSize;
- (UIImage *_Nullable)erode:(CGSize)kernelSize;
- (UIImage *_Nullable)elementwiseMinimum:(UIImage *_Nonnull)img;
- (UIImage *_Nullable)resizeTo:(CGSize)minSize;
- (UIImage *_Nullable)rectangle;

- (UIImageContours *_Nonnull)contoursFilteredBy:(nullable BOOL (^)(Contour *_Nonnull contour))filter NS_SWIFT_NAME(contours(filteredBy:));
@end
