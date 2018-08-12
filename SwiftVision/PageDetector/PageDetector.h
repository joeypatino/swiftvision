#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

@interface PageDetector : NSObject
/** Returns the page boundary outline struct */
- (CGRectOutline)pageBounds:(UIImage *_Nonnull)image;
/** Returns an new UIImage with the page area masked against a
 * white background */
- (UIImage *_Nullable)extractPage:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)extract:(CGRectOutline)outline fromImage:(UIImage *_Nonnull)image;
/** Returns image with a boundary indicator rendered around the frame of the
 * largest contour. */
- (UIImage *_Nullable)renderPageBounds:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)render:(CGRectOutline)outline inImage:(UIImage *_Nonnull)image;

- (CGRectOutline)norm2Pix:(CGRectOutline)outline size:(CGSize)size;


// Helpers
- (UIImage *_Nullable)gray:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)blurred:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)dialate1:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)threshhold:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)canny:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)dialate2:(UIImage *_Nonnull)image;
@end
