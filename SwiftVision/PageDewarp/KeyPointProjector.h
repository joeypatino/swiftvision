#import <UIKit/UIKit.h>

@interface KeyPointProjector : NSObject
- (NSArray <NSValue *> *)projectKeypoints:(NSArray <NSValue *> *)keyPoints of:(std::vector<double>)vectors;
- (NSArray <NSValue *> *)projectXY:(NSArray <NSValue *> *)xyCoordsArr of:(std::vector<double>)vectors;
@end
