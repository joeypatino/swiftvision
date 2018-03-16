#import <UIKit/UIKit.h>

@interface ImageRemapper: NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithImage:(UIImage * _Nonnull)image
                    remappingKeypoints:(std::vector<std::vector<cv::Point2d>>)keyPoints NS_DESIGNATED_INITIALIZER;
- (UIImage *_Nullable)remap;
@end

