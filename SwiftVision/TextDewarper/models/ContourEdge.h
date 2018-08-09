#import <Foundation/Foundation.h>

@class Contour;
@interface ContourEdge: NSObject
/// a computed score
@property (nonatomic, assign, readonly) double score;
/// the distance along the x axis between contourA and contourB
@property (nonatomic, assign, readonly) double distance;
/// the difference between the angle of contourA and contourB
@property (nonatomic, assign, readonly) double angle;
/// the edge overlap (x axis) between contourA and contourB
@property (nonatomic, assign, readonly) double overlap;
@property (nonatomic, strong, readonly) Contour *_Nonnull contourA;
@property (nonatomic, strong, readonly) Contour *_Nonnull contourB;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
@end
