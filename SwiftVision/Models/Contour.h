#import <UIKit/UIKit.h>

@class ContourEdge;
@interface Contour: NSObject
@property (nonatomic, assign, readonly) CGPoint *_Nonnull points;
@property (nonatomic, assign, readonly) CGRect bounds;
@property (nonatomic, assign, readonly) CGFloat aspect;
@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, assign, readonly) CGFloat area;

@property (nonatomic, assign, readonly) double center;
@property (nonatomic, assign, readonly) double tangent;
@property (nonatomic, assign, readonly) double angle;

- (ContourEdge * _Nullable)generateEdge:(Contour * _Nonnull)adjacentContour;
@end
