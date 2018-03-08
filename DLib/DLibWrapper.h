#import <UIKit/UIKit.h>

@interface DLibWrapper: NSObject
- (void)optimize:(NSArray <NSNumber *> *)params to:(NSArray <NSValue *> *)dstPoints keyPointIdx:(NSArray <NSValue *> *)keyPointIndexes;
- (void)minimize:(NSArray <NSNumber *> *)xyCoordsArr to:(NSArray <NSValue *> *)dstpoints;
@end
