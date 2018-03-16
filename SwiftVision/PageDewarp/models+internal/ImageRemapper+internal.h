#ifndef ImageRemapper_internal_h
#define ImageRemapper_internal_h

@interface ImageRemapper()
@property (nonatomic, assign, readonly) CGRectOutline corners;
@property (nonatomic, assign, readonly) std::vector<int> spanCounts;
@property (nonatomic, assign, readonly) std::vector<std::vector<cv::Point2d>> allKeypoints;
@property (nonatomic, assign, readonly) std::vector<std::vector<double>> xCoordinates;
@property (nonatomic, assign, readonly) std::vector<double> yCoordinates;
@property (nonatomic, assign, readonly) CGSize dimensions;
@property (nonatomic, assign, readonly) EigenVector eigenVector;
@property (nonatomic, strong, readonly) UIImage *inputImage;

- (std::vector<double>)defaultParameters;
- (std::vector<cv::Point2d>)keyPointIndexesForSpanCounts:(std::vector<int>)spanCounts;
- (std::vector<cv::Point2d>)destinationPoints:(std::vector<std::vector<cv::Point2d>>)spanPoints;
@end

#endif /* ImageRemapper_internal_h */
