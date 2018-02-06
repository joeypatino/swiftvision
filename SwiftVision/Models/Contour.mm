#import "Contour.h"

@implementation Contour
- (instancetype)initWithCVMat:(cv::Mat)cvMat {
    self = [super init];
    self.size = cvMat.total();
//    memset(self.points, 0, sizeof(CGPoint) * self.size);
    self.points = (CGPoint *)malloc(sizeof(CGPoint) * self.size);

    for (int i = 0; i < cvMat.total(); i++) {
        cv::Point p = cvMat.at<cv::Point>(i);
        self.points[i] = CGPointMake(p.x, p.y);
    }

    return self;
}

- (void)dealloc {
    free(self.points);
}
@end
