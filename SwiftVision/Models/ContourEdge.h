#import <UIKit/UIKit.h>

@class Contour;
@interface ContourEdge : NSObject
@property (nonatomic, assign, readonly) CGFloat score;
@property (nonatomic, strong, readonly) Contour *contourA;
@property (nonatomic, strong, readonly) Contour *contourB;
@end
