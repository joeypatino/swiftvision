#import <Foundation/Foundation.h>

@class ContourEdge;
@interface Contour: NSObject
/// the minimal up-right bounding rectangle of the contour.
@property (nonatomic, assign, readonly) CGRect bounds;
/// the aspect ratio of the contour.
@property (nonatomic, assign, readonly) CGFloat aspect;
/// the number of points contained in the contour
@property (nonatomic, assign, readonly) NSInteger size;
/// the area of the contour.
@property (nonatomic, assign, readonly) CGFloat area;
/// the center point of the contour
@property (nonatomic, assign, readonly) CGPoint center;
/// the tangent of the contour
@property (nonatomic, assign, readonly) CGPoint tangent;
/// the angle of the contour
@property (nonatomic, assign, readonly) double angle;
@property (nonatomic, assign, readonly) CGFloat localxMin;
@property (nonatomic, assign, readonly) CGFloat localxMax;
/// the previous contour in the span of contours that this contour belongs to
@property (nonatomic, strong) Contour *_Nullable previous;
/// the next contour in the span of contours that this contour belongs to
@property (nonatomic, strong) Contour *_Nullable next;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
@end
