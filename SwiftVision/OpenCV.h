#import <UIKit/UIKit.h>

@interface OpenCV : NSObject
+ (NSString *)version;
+ (UIImage *)resize:(UIImage *)img to:(CGSize)minSize;

@end
