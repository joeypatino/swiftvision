#import "OpenCV.h"
#import "UIImage+OpenCV.h"

@implementation OpenCV
+ (NSString *)version {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

@end
