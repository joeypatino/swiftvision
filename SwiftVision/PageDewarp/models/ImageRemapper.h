#import <UIKit/UIKit.h>

@interface ImageRemapper: NSObject
- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithOriginalImage:(UIImage *_Nonnull)image
                                  workingImage:(UIImage *_Nonnull)workingImage
                            remappingKeypoints:(std::vector<std::vector<cv::Point2d>>)keyPoints NS_DESIGNATED_INITIALIZER;
- (UIImage *_Nullable)remap;
- (UIImage *_Nullable)preCorrespondenceKeyPoints;
- (UIImage *_Nullable)postCorresponenceKeyPoints;
@end

