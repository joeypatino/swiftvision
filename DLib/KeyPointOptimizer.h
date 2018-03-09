#import <UIKit/UIKit.h>
#include <iostream>

@interface KeyPointOptimizer: NSObject
@property (nonatomic, strong, readonly) NSArray <NSNumber *> *_Nonnull baseParameters;
@property (nonatomic, strong, readonly) NSArray <NSValue *> *_Nonnull destinationPoints;
@property (nonatomic, strong, readonly) NSArray <NSValue *> *_Nonnull keyPointIndexes;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithBaseParameters:(NSArray <NSNumber *> *_Nonnull)params
                              destinationPoints:(NSArray <NSValue *> *_Nonnull)dstPoints
                                keyPointIndexes:(NSArray <NSValue *> *_Nonnull)keyPointIndexes NS_DESIGNATED_INITIALIZER;
- (void)optimizeWithObjective:(double (^ _Nonnull )(std::vector<double> vector))objective;
@end
