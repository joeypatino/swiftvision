#ifndef ContourSpan_internal_h
#define ContourSpan_internal_h

#import <opencv2/opencv.hpp>

@interface ContourSpan ()
- (instancetype _Nonnull)initWithImage:(UIImage *_Nonnull)image contours:(NSArray <Contour *> *_Nonnull)contours NS_DESIGNATED_INITIALIZER;
/// the sampled points in the span (normalized)
@property (nonatomic, assign, readonly) std::vector<cv::Point2d> spanPoints;
/// the keypoints sampled along this span
@property (nonatomic, assign, readonly) std::vector<cv::Point2d> keyPoints;
/// the interval of each sampled point in the span
@property (nonatomic, assign) int samplingStep;
@end

#endif /* ContourSpan_internal_h */
