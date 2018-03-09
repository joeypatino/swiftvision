#import <UIKit/UIKit.h>

@interface ContourSpanInfo: NSObject
@property (nonatomic, assign, readonly) struct CGRectOutline corners;
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull spanCounts;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (NSArray <NSNumber *> *_Nonnull)defaultParameters;
- (NSArray <NSValue *> *_Nonnull)keyPointIndexesForSpanCounts:(NSArray <NSNumber *> *_Nonnull)spanCounts;
- (NSArray <NSValue *> *_Nonnull)destinationPoints:(NSArray <NSArray <NSValue *> *> *_Nonnull)spanPoints;
@end
