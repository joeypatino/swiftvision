#ifndef ContourSpanInfo_internal_h
#define ContourSpanInfo_internal_h

@interface ContourSpanInfo()
@property (nonatomic, assign, readonly) std::vector<std::vector<double>> xCoordinates;
@property (nonatomic, assign, readonly) std::vector<double> yCoordinates;
@property (nonatomic, assign, readonly) CGSize roughDimensions;
- (instancetype _Nonnull)initWithCorners:(CGRectOutline)corners
                            xCoordinates:(std::vector<std::vector<double>>)xCoordinates
                            yCoordinates:(std::vector<double>)yCoordinates;

@end

#endif /* ContourSpanInfo_internal_h */
