#import <UIKit/UIKit.h>

@interface ContourSpanInfo: NSObject
@property (nonatomic, assign, readonly) struct CGRectOutline corners;
@property (nonatomic, assign, readonly) std::vector<int> spanCounts;
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (std::vector<double>)defaultParameters;
- (std::vector<cv::Point2d>)keyPointIndexesForSpanCounts:(std::vector<int>)spanCounts;
- (std::vector<cv::Point2d>)destinationPoints:(std::vector<std::vector<cv::Point2d>>)spanPoints;
@end
