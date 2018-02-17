#ifndef ContourEdge_internal_h
#define ContourEdge_internal_h

@interface ContourEdge ()
- (instancetype _Nonnull)initWithDistance:(double)distance
                                    angle:(double)angle
                                  overlap:(double)xOverlap
                                 contourA:(Contour *_Nonnull)contourA
                                 contourB:(Contour *_Nonnull)contourB NS_DESIGNATED_INITIALIZER;
@end

#endif /* ContourEdge_internal_h */
