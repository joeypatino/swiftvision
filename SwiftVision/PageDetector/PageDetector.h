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

- (UIImage *_Nullable)deskew:(UIImage *_Nonnull)image withOutline:(CGRectOutline)outline;

// normalize a CGRectOutline
- (CGRectOutline)norm2Pix:(CGRectOutline)outline size:(CGSize)size;

// debug Helpers
- (UIImage *_Nullable)process:(UIImage *_Nonnull)image;
@end
