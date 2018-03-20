#ifndef ImageRemapper_internal_h
#define ImageRemapper_internal_h

@interface ImageRemapper()
@property (nonatomic, assign, readonly) CGRectOutline corners;
@property (nonatomic, assign, readonly) std::vector<int> numKeyPointsPerSpan;
@property (nonatomic, assign, readonly) std::vector<std::vector<cv::Point2d>> keyPoints;
@property (nonatomic, assign, readonly) std::vector<std::vector<double>> *xCoordinates;
@property (nonatomic, assign, readonly) std::vector<double> *yCoordinates;
@property (nonatomic, assign, readonly) CGSize normalizedDimensions;
@property (nonatomic, assign, readonly) EigenVector eigenVector;
@property (nonatomic, strong, readonly) UIImage *inputImage;
@property (nonatomic, strong, readonly) UIImage *workingImage;

@property (nonatomic, assign, readonly) std::vector<double> *pxCoords;
@property (nonatomic, assign, readonly) std::vector<double> *pyCoords;

- (std::vector<double>)defaultParameters;
- (std::vector<cv::Point2d>)keyPointIndexes:(std::vector<int>)numKeyPointsPerSpan;
- (std::vector<cv::Point2d>)destinationPoints:(std::vector<std::vector<cv::Point2d>>)keyPoints;
@end

#endif /* ImageRemapper_internal_h */
