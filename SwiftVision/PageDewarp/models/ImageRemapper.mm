#import <opencv2/opencv.hpp>
#include <numeric>
#import "ImageRemapper.h"
// structs
#import "CGRectOutline.h"
#import "EigenVector.h"
// private
#import "ImageRemapper+internal.h"
// extras
#import "functions.h"
#import "NSArray+extras.h"
// optimization
#import "Optimizer.hpp"
#import "KeyPointCostFunction.hpp"
#import "CornerPointCostFunction.hpp"

static inline struct EigenVector
EigenVectorMake(cv::Point2f x, cv::Point2f y) {
    struct EigenVector eigen;
    eigen.x = geom::convertTo(x);
    eigen.y = geom::convertTo(y);
    return eigen;
}

@interface ImageRemapper ()
@property (nonatomic, strong) NSArray <NSNumber *> *pxCoords;
@property (nonatomic, strong) NSArray <NSNumber *> *pyCoords;
@end

@implementation ImageRemapper
- (instancetype _Nonnull)initWithImage:(UIImage *)image remappingKeypoints:(std::vector<vector<cv::Point2d>>)keyPoints {
    self = [super init];
    _inputImage = image;
    _allKeypoints = keyPoints;
    _eigenVector = [self eigenVectorWithKeyPoints:keyPoints];
    _pxCoords = [self normalizedCoordsWithEigenVectorDir:self.eigenVector.x];
    _pyCoords = [self normalizedCoordsWithEigenVectorDir:self.eigenVector.y];
    _corners = [self outlineWithEigenVector:self.eigenVector];

    _xCoordinates = [self generateCoordinatesX:keyPoints withEigenVector:self.eigenVector];
    _yCoordinates = [self generateCoordinatesY:keyPoints withEigenVector:self.eigenVector];

    return self;
}

- (UIImage *)remap {
    OptimizerResult optimizeImgRes = [self optimizeImage];
    OptimizerResult optimizeCornRes = [self optimizeImageCornersWithOptimizedKeypoints:optimizeImgRes.x];

    return [[UIImage alloc] init];
}

- (OptimizerResult)optimizeImage {
    std::vector<cv::Point2d> keyPointIndexes = [self keyPointIndexesForSpanCounts:self.spanCounts];
    std::vector<cv::Point2d> dstpoints = [self destinationPoints:self.allKeypoints];

    Ptr<KeyPointCostFunction> fn = Ptr<KeyPointCostFunction>(new KeyPointCostFunction(dstpoints, keyPointIndexes));
    Optimizer opt = Optimizer(fn, self.defaultParameters);

    printf("initial objective is %f\n",  opt.initialOptimization().fun);
    OptimizerResult res = opt.optimize();
    printf("optimization took: %f seconds\n", res.dur);
    printf("final objective is %f\n", res.fun);

    return res;
}

- (OptimizerResult)optimizeImageCornersWithOptimizedKeypoints:(std::vector<double>)keyPoints {
    vector<Point2d> dstpoints = {Point2d(self.corners.botRight.x, self.corners.botRight.y)};
    vector<double> params = {self.normalizedDimensions.width, self.normalizedDimensions.height};

    Ptr<CornerPointCostFunction> fn = Ptr<CornerPointCostFunction>(new CornerPointCostFunction(dstpoints, keyPoints));
    Optimizer opt = Optimizer(fn, params);

    printf("initial objective is %f\n",  opt.initialOptimization().fun);
    OptimizerResult res = opt.optimize();
    printf("optimization took: %f seconds\n", res.dur);
    printf("final objective is %f\n", res.fun);
    return res;
}


- (NSString *)description {
    NSMutableString *formatedDesc = [NSMutableString string];
    [formatedDesc appendFormat:@"<%@: %p", NSStringFromClass([self class]), self];
    [formatedDesc appendFormat:@",\n [%@, \n%@, \n%@, \n%@]",
     NSStringFromCGPoint(self.corners.topLeft),
     NSStringFromCGPoint(self.corners.topRight),
     NSStringFromCGPoint(self.corners.botRight),
     NSStringFromCGPoint(self.corners.botLeft)];
    [formatedDesc appendFormat:@">"];
    return formatedDesc;
}

- (CGSize)normalizedDimensions {
    CGPoint w = geom::subtract(self.corners.topRight, self.corners.topLeft);
    CGPoint h = geom::subtract(self.corners.botLeft, self.corners.topLeft);
    double pageWidth = norm(Mat(geom::convertTo(w)));
    double pageHeight = norm(Mat(geom::convertTo(h)));
    return CGSizeMake(pageWidth, pageHeight);
}

- (std::vector<double>)defaultParameters {
    CGSize dimensions = self.normalizedDimensions;

    // Array of object points in the object coordinate space
    std::vector<cv::Point3d> cornersObject3d = {
        cv::Point3d(0, 0, 0),
        cv::Point3d(dimensions.width, 0, 0),
        cv::Point3d(dimensions.width, dimensions.height, 0),
        cv::Point3d(0, dimensions.height, 0)};

    // Array of corresponding image points
    std::vector<cv::Point2d> imagePoints = nsarray::convertTo2d(nsarray::pointsFrom(self.corners));

    std::vector<cv::Point3d> camera = {
        cv::Point3d(1.8,0.0,0.0),
        cv::Point3d(0.0,1.8,0.0),
        cv::Point3d(0.0,0.0,1.0)
    };

    // output rotation vectors
    std::vector<double> rvec;
    // output translation vectors
    std::vector<double> tvec;

    // estimate rotation and translation from four 2D-to-3D point correspondences
    cv::solvePnP(cornersObject3d,
                 imagePoints,
                 cv::Mat(3, 3, cv::DataType<double>::type, &camera),
                 cv::Mat::zeros(5, 1, cv::DataType<double>::type),
                 rvec,
                 tvec);

    // our initial guess for the cubic has no slope
    std::vector<double> cubicSlope = std::vector<double>({0.0, 0.0});

    rvec = {
        -0.00000000,
        0.00000000,
        0.01341045
    };
    tvec = {
        -0.74919273,
        -1.01938189,
        1.79999995
    };
    std::vector<double> params;
    for (int i = 0; i < int(rvec.size()); i++) {
        params.push_back(rvec[i]);
    }
    for (int i = 0; i < int(tvec.size()); i++) {
        params.push_back(tvec[i]);
    }
    for (int i = 0; i < int(cubicSlope.size()); i++) {
        params.push_back(cubicSlope[i]);
    }
    for (int i = 0; i < self.yCoordinates.size(); i++) {
        params.push_back(self.yCoordinates[i]);
    }
    for (int i = 0; i < self.xCoordinates.size(); i++) {
        std::vector<double> values = self.xCoordinates[i];
        for (int j = 0; j < values.size(); j++) {
            params.push_back(values[j]);
        }
    }

    //logs::describe_vector(cornersObject3d, "cornersObject3d");
    //logs::describe_vector(imagePoints, "corners");
    //logs::describe_vector(camera, "K");
    //logs::describe_vector(rvec, "rvec");
    //logs::describe_vector(tvec, "tvec");

    return params;
}

- (std::vector<int>)spanCounts {
    std::vector<int> counts;
    for (int i = 0; i < self.xCoordinates.size(); i++) {
        std::vector<double> values = self.xCoordinates[i];
        counts.push_back(int(values.size()));
    }
    return counts;
}

- (std::vector<cv::Point2d>)keyPointIndexesForSpanCounts:(std::vector<int>)spanCounts {
    int npts = std::accumulate(spanCounts.begin(), spanCounts.end(), 0);
    std::vector<std::vector<int>> keyPointIdx = std::vector<std::vector<int>>(2, std::vector<int>(npts+1, 0));
    int start = 1;
    for (int i = 0; i < spanCounts.size(); i++) {
        int count = spanCounts[i];
        int end = start + count;
        for (int r = start; r < end; r++) {
            keyPointIdx[1][r] = 8+i;
        }
        start = end;
    }

    for (int i = 0; i < npts; i++) {
        keyPointIdx[0][i+1] = i + 8 + int(spanCounts.size());
    }
    std::vector<cv::Point2d> keypoints;
    keypoints.reserve(npts+1);
    for (int i = 0; i < npts+1; i++) {
        cv::Point2d kp = cv::Point2d(keyPointIdx[0][i], keyPointIdx[1][i]);
        keypoints.push_back(kp);
    }
    return keypoints;
}

- (std::vector<cv::Point2d>)destinationPoints:(std::vector<std::vector<cv::Point2d>>)keyPoints {
    std::vector<cv::Point2d> destinationPoints;
    destinationPoints.push_back(cv::Point2d(self.corners.topLeft.x, self.corners.topLeft.y));

    for (int i = 0; i < keyPoints.size(); i++) {
        std::vector<cv::Point2d> points = keyPoints[i];
        for (int j = 0; j < points.size(); j++) {
            destinationPoints.push_back(points[j]);
        }
    }
    return destinationPoints;
}

// MARK: -
- (EigenVector)eigenVectorWithKeyPoints:(std::vector<vector<cv::Point2d>>)keyPoints {
    double eigenInit[] = {0, 0};
    double allWeights = 0.0;
    cv::Mat allEigenVectors = cv::Mat(1, 2, cv::DataType<double>::type, eigenInit);

    for (int i = 0; i < keyPoints.size(); i++) {
        std::vector<cv::Point2d> vectorPoints = keyPoints[i];
        cv::Mat mean = cv::Mat();
        cv::Mat eigen = cv::Mat();
        cv::Mat computePoints = cv::Mat(vectorPoints).reshape(1);
        cv::PCACompute(computePoints, mean, eigen, 1);

        cv::Point2d firstP = vectorPoints[0];
        cv::Point2d lastP = vectorPoints[vectorPoints.size() -1];
        cv::Point2d point = lastP - firstP;
        double weight = cv::norm(point);

        cv::Mat eigenMul = eigen.mul(weight);
        allEigenVectors += eigenMul;
        allWeights += weight;
    }

    cv::Mat outEigenVec = allEigenVectors / allWeights;
    double eigenX = outEigenVec.at<double>(0, 0);
    double eigenY = outEigenVec.at<double>(0, 1);
    if (eigenX < 0) {
        eigenX *= -1;
        eigenY *= -1;
    }

    cv::Point2d xDir = cv::Point2d(eigenX, eigenY);
    cv::Point2d yDir = cv::Point2d(-eigenY, eigenX);

    return EigenVectorMake(xDir, yDir);
}

- (NSArray <NSNumber *> *)normalizedCoordsWithEigenVectorDir:(CGPoint)eigenDir {
    CGSize sz = self.inputImage.size;
    cv::Point2d eigenVec = geom::convertTo(eigenDir);
    CGRectOutline rectOutline = geom::outlineWithSize(sz);
    NSArray <NSValue *> *pts = @[[NSValue valueWithCGPoint:rectOutline.topLeft],
                                 [NSValue valueWithCGPoint:rectOutline.topRight],
                                 [NSValue valueWithCGPoint:rectOutline.botRight],
                                 [NSValue valueWithCGPoint:rectOutline.botLeft]];
    NSArray <NSValue *> *normalizedPts = nsarray::pix2norm(sz, pts);
    return nsarray::dotProduct(normalizedPts, eigenVec);
}

- (CGRectOutline)outlineWithEigenVector:(EigenVector)eigenVector {
    double px0 = self.pxCoords.min.doubleValue;
    double px1 = self.pxCoords.max.doubleValue;
    double py0 = self.pyCoords.min.doubleValue;
    double py1 = self.pyCoords.max.doubleValue;
    cv::Point2d eigenVectorx = geom::convertTo(eigenVector.x);
    cv::Point2d eigenVectory = geom::convertTo(eigenVector.y);

    // tl
    cv::Point2d p00 = px0 * eigenVectorx + py0 * eigenVectory;
    // tr
    cv::Point2d p01 = px1 * eigenVectorx + py0 * eigenVectory;
    // br
    cv::Point2d p11 = px1 * eigenVectorx + py1 * eigenVectory;
    // bl
    cv::Point2d p10 = px0 * eigenVectorx + py1 * eigenVectory;

    return CGRectOutlineMake(geom::convertTo(p00),
                             geom::convertTo(p10),
                             geom::convertTo(p11),
                             geom::convertTo(p01));
}

- (std::vector<double>)generateCoordinatesY:(std::vector<std::vector<cv::Point2d>>)keyPoints
withEigenVector:(EigenVector)eigenVector {
    double py0 = self.pyCoords.min.doubleValue;
    std::vector<double> ycoords;
    for (int i = 0; i < keyPoints.size(); i++) {
        std::vector<cv::Point2d> spanPoints = keyPoints[i];
        std::vector<double> pyCoords = vectors::dotProduct(spanPoints, geom::convertTo(eigenVector.y));
        double meanY = 1.0 * std::accumulate(pyCoords.begin(), pyCoords.end(), 0LL) / pyCoords.size();
        ycoords.push_back(meanY - py0);
    }
    return ycoords;
}

- (std::vector<std::vector<double>>)generateCoordinatesX:(std::vector<std::vector<cv::Point2d>>)keyPoints
withEigenVector:(EigenVector)eigenVector {
    double px0 = self.pxCoords.min.doubleValue;
    std::vector<std::vector<double>> xcoords;
    for (int i = 0; i < keyPoints.size(); i++) {
        std::vector<cv::Point2d> spanPoints = keyPoints[i];
        std::vector<double> pxCoords = vectors::dotProduct(spanPoints, geom::convertTo(eigenVector.x));
        xcoords.push_back(vectors::subtract(pxCoords, px0));
    }

    return xcoords;
}

// Testing
- (std::vector<double>)testDefaultParameters {
    std::vector<cv::Point3d> corner_object3d = {
        cv::Point3d(0.00000000,0.00000000,0.00000000),
        cv::Point3d(1.52559066,0.00000000,0.00000000),
        cv::Point3d(1.52559066,2.01848703,0.00000000),
        cv::Point3d(0.00000000,2.01848703,0.00000000)
    };
    std::vector<cv::Point2d> corners = {
        cv::Point2d(-0.74919273,-1.01938189),
        cv::Point2d(0.77626074,-0.99892364),
        cv::Point2d(0.74919273,1.01938189),
        cv::Point2d(-0.77626074,0.99892364)
    };
    std::vector<cv::Point3d> camera = {
        cv::Point3d(1.8,0.0,0.0),
        cv::Point3d(0.0,1.8,0.0),
        cv::Point3d(0.0,0.0,1.0)
    };
    cv::Mat K = Mat(3, 3, cv::DataType<double>::type, &camera);
    cv::Mat rvec;
    cv::Mat tvec;

    cv::Mat inliers;
    cv::solvePnPRansac(corner_object3d,
                       corners,
                       K,
                       cv::Mat::zeros(5, 1, CV_64FC1),
                       rvec, tvec,
                       false,
                       500,
                       2.0,
                       0.95,
                       inliers,
                       cv::SOLVEPNP_ITERATIVE);

    logs::describe_vector(corner_object3d, "corner_object3d");
    logs::describe_vector(corners, "corners");
    logs::describe_vector(camera, "K");
    logs::describe_vector(rvec, "rvec");
    logs::describe_vector(tvec, "tvec");

    /**
     expected rvec:
     --------------
     [-0.00000000]
     [0.00000000]
     [0.01341045]

     expected tvec:
     --------------
     [-0.74919273]
     [-1.01938189]
     [1.79999995]
     */
    return {};
}

@end
