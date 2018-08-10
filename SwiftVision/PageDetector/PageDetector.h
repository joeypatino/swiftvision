#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

@interface PageDetector : NSObject
- (CGRectOutline)pageBounds:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)extractPage:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)extractPage:(CGRectOutline)outline fromImage:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)renderedPageBounds:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)renderPageBounds:(CGRectOutline)outline forImage:(UIImage *_Nonnull)image;
@end
