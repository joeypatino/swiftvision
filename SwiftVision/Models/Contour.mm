#import <opencv2/opencv.hpp>
#import "Contour.h"

@interface Contour ()
@property (nonatomic, assign) cv::Mat mat;
@end

#define ContourBasicDebugInfo
//#define ContourDetailedDebugInfo

// MARK: -
@implementation Contour
- (instancetype)initWithCVMat:(cv::Mat)cvMat {
    self = [super init];
    self.mat = cvMat;
    cv::Rect boundingRect = cv::boundingRect(cvMat);

    _size = cvMat.total();
    _bounds = CGRectMake(boundingRect.x, boundingRect.y, boundingRect.width, boundingRect.height);
    _points = (CGPoint *)malloc(sizeof(CGPoint) * _size);
    _aspect = boundingRect.height / boundingRect.width;
    _area = cv::contourArea(cvMat);

    for (int i = 0; i < cvMat.total(); i++) {
        cv::Point p = cvMat.at<cv::Point>(i);
        _points[i] = CGPointMake(p.x, p.y);
    }

    return self;
}

- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@", POINTS: %li", (long)self.size];
#ifdef ContourBasicDebugInfo
    [formatedDesc appendFormat:@", BOUNDS: %@", [self shortDescription]];
#endif
#ifdef ContourDetailedDebugInfo
    [formatedDesc appendFormat:@", [%@]", [self longDescription]];
#endif
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}

- (void)dealloc {
    free(self.points);
}

// MARK: -

- (NSString *)longDescription {
    NSMutableString *description = [NSMutableString string];
    for (int idx = 0; idx < self.size; idx++) {
        [description appendFormat:@"%@", NSStringFromCGPoint(self.points[idx])];
        if (idx < self.size - 1) [description appendFormat:@", "];
    }
    return description;
}

- (NSString *)shortDescription {
    return [NSString stringWithFormat:@"%@", NSStringFromCGRect(self.bounds)];
}

@end
