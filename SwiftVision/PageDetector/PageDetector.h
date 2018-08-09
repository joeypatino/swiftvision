#import <UIKit/UIKit.h>
#import "CGRectOutline.h"

@interface PageDetector : NSObject
- (CGRectOutline)detectPage:(UIImage *_Nonnull)image;
- (UIImage *_Nullable)debug:(UIImage *_Nonnull)image;
@end
