#import <Foundation/Foundation.h>

@class Contour;
@interface ContourSpan : NSObject
/// the contours in this span.
@property (nonatomic, retain, readonly) NSArray <Contour *> *_Nonnull contours;
/// add a contour to this span.
- (void)addContour:(Contour * _Nonnull)contour;
@end
