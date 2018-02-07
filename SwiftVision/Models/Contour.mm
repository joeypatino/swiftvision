#import "Contour.h"

@interface Contour ()
@property (nonatomic, assign) cv::Mat mat;
@end

@implementation Contour
- (instancetype)initWithCVMat:(cv::Mat)cvMat {
    self = [super init];
    self.mat = cvMat;
    self.size = cvMat.total();
    self.points = (CGPoint *)malloc(sizeof(CGPoint) * self.size);

    for (int i = 0; i < cvMat.total(); i++) {
        cv::Point p = cvMat.at<cv::Point>(i);
        self.points[i] = CGPointMake(p.x, p.y);
    }
    return self;
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"%@ ", [super description]];
    [formatedDesc appendFormat:@"{%li} :: ", (long)self.size];
    [formatedDesc appendFormat:@"["];

    for (int idx = 0; idx < self.size; idx++) {
        CGPoint point = self.points[idx];
        [formatedDesc appendFormat:@"%@", NSStringFromCGPoint(point)];
        if (idx < self.size - 1) {
            [formatedDesc appendFormat:@", "];
        }
    }
    [formatedDesc appendFormat:@"]"];

    return formatedDesc;
}

- (void)dealloc {
    free(self.points);
}

@end
