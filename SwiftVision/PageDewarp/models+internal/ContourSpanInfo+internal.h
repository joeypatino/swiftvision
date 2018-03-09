#ifndef ContourSpanInfo_internal_h
#define ContourSpanInfo_internal_h

@interface ContourSpanInfo()
@property (nonatomic, strong, readonly) NSArray <NSArray <NSNumber *> *> *_Nonnull xCoordinates;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull yCoordinates;
@property (nonatomic, assign, readonly) CGSize roughDimensions;
- (instancetype _Nonnull)initWithCorners:(CGRectOutline)corners
                            xCoordinates:(NSArray <NSArray <NSNumber *> *> *_Nonnull)xCoordinates
                            yCoordinates:(NSArray <NSNumber *> *_Nonnull)yCoordinates;
@end

#endif /* ContourSpanInfo_internal_h */
