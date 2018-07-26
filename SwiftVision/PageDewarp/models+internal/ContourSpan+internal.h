#ifndef ContourSpan_internal_h
#define ContourSpan_internal_h

@interface ContourSpan ()
- (instancetype _Nonnull)initWithImage:(UIImage *_Nonnull)image contours:(NSArray <Contour *> *_Nonnull)contours NS_DESIGNATED_INITIALIZER;
/// the sampled points in the span (normalized)
@property (nonatomic, strong, readonly) NSArray <NSValue *> *_Nonnull spanPoints;
/// the interval of each sampled point in the span
@property (nonatomic, assign) int samplingStep;
@end

#endif /* ContourSpan_internal_h */
