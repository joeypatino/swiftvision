#import <UIKit/UIKit.h>

@interface ContourSpanInfo: NSObject
@property (nonatomic, assign, readonly) struct CGRectOutline corners;
@property (nonatomic, strong, readonly) NSArray <NSArray <NSNumber *> *> *_Nonnull xCoordinates;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull yCoordinates;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull spanCounts;
@property (nonatomic, assign, readonly) CGSize roughDimensions;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (NSArray <NSNumber *> *_Nonnull)defaultParmeters;
- (NSArray <NSValue *> *_Nonnull)keyPointIndexes:(NSArray <NSNumber *> *_Nonnull)spanCounts;
@end
