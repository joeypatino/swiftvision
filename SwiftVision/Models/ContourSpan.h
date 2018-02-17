#import <Foundation/Foundation.h>

@class Contour;
@interface ContourSpan : NSObject
- (void)addContour:(Contour * _Nonnull)contour;
- (void)removeContour:(Contour * _Nonnull)contour;
@end
