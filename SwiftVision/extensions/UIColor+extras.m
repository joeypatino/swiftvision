#import "UIColor+extras.h"

@implementation UIColor (extras)
+ (UIColor *)randomColor {
    CGFloat red = arc4random_uniform(255) / 255.0;
    CGFloat green = arc4random_uniform(255) / 255.0;
    CGFloat blue = arc4random_uniform(255) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}
@end
