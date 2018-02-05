#import <opencv2/opencv.hpp>
#import "OpenCV.h"

@implementation OpenCV
+ (NSString *)version {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}
@end
