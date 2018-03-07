#ifndef Contour_internal_h
#define Contour_internal_h

#import <opencv2/opencv.hpp>

using namespace cv;

@interface Contour ()
// the original opencv mat.
@property (nonatomic, assign) Mat opencvContour;
// a bounding box mask of the contour (non minimum)
@property (nonatomic, assign, readonly) Mat mask;
@property (nonatomic, assign, readonly) CGPoint clxMin;
@property (nonatomic, assign, readonly) CGPoint clxMax;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull clx;
@property (nonatomic, assign, readonly) NSArray <NSValue *> *_Nonnull points;
@property (nonatomic, assign) Moments moments;
/// returns the contour from a Mat
- (instancetype _Nonnull)initWithCVMat:(Mat)cvMat NS_DESIGNATED_INITIALIZER;
/// constructs a contourEdge with an adjacent contour
- (ContourEdge *_Nullable)contourEdgeWithAdjacentContour:(Contour *_Nonnull)adjacentContour;
// returns the minimum bounding box vertices of the contour
- (void)getBoundingVertices:(cv::Point *_Nonnull)pts;
@end

#endif /* Contour_internal_h */
