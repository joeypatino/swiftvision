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
#import "math+extras.hpp"
#import "UIImage+Mat.h"
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
@property (nonatomic, assign, readonly) KeyPointProjector *projector;
@end

@implementation ImageRemapper
- (instancetype)initWithOriginalImage:(UIImage *)image
                         workingImage:(UIImage *)workingImage
                   remappingKeypoints:(std::vector<vector<cv::Point2d>>)keyPoints {
    self = [super init];
    _inputImage = image;
    _workingImage = workingImage;
    _keyPoints = keyPoints;
    CGRectOutline outline = geom::outlineWithSize(self.workingImage.size);

    _projector = new KeyPointProjector();
    _eigenVector = [self eigenVector:keyPoints];

    _pxCoords = new vector_d([self normalizeOutline:outline with:self.eigenVector.x]);
    _pyCoords = new vector_d([self normalizeOutline:outline with:self.eigenVector.y]);
    _corners = [self outlineWithEigenVector:self.eigenVector];

    _xCoordinates = new vector_dd([self generateCoordinatesX:keyPoints withEigenVector:self.eigenVector]);
    _yCoordinates = new vector_d([self generateCoordinatesY:keyPoints withEigenVector:self.eigenVector]);

    return self;
}

- (void)dealloc {
    delete _pxCoords;
    delete _pyCoords;
    delete _projector;
    delete _xCoordinates;
    delete _yCoordinates;
}

- (UIImage *)remap {
    int REMAP_DECIMATE = 16.0;
    int height = math::round(0.5 * self.normalizedDimensions.height * 1.0 * self.inputImage.size.height, REMAP_DECIMATE);
    int width = math::round(height * self.normalizedDimensions.width / self.normalizedDimensions.height, REMAP_DECIMATE);
    cout << "input was " << self.inputImage.size.width << "x" << self.inputImage.size.height << endl;
    cout << "output will be " << width << "x" << height << endl;

    int heightSmall = height / REMAP_DECIMATE;
    int widthSmall = width / REMAP_DECIMATE;

    vector_d pageXRng = math::linspace(0, self.normalizedDimensions.width, widthSmall);
    vector_d pageYRng = math::linspace(0, self.normalizedDimensions.height, heightSmall);

    int xsize = int(pageXRng.size());
    int ysize = int(pageYRng.size());
    vector_dd xx = vector_dd(ysize, vector_d(xsize, 0));
    vector_dd yy = vector_dd(ysize, vector_d(xsize, 0));
    vectors::meshgrid(pageXRng, pageYRng, &xx, &yy);

    vector_dd xx_flat = vectors::reshape(xx, int(xx.size()), 1);
    vector_dd yy_flat = vectors::reshape(yy, int(yy.size()), 1);
    vector_dd xy = vectors::hstack(xx_flat, yy_flat);

    vector_d p = self.defaultParameters;
//    OptimizerResult res = [self optimizeImage];
//    OptimizerResult res2 = [self optimizeImageCornersWithOptimizedKeypoints:res.x];
//    vector_d p = res2.x;

    cv::Size inputShape = cv::Size(self.inputImage.size.height, self.inputImage.size.width);
    std::vector<cv::Point2d> projectedPoints = self.projector->projectXY(xy, p.data());
    std::vector<cv::Point2d> imagePoints = vectors::norm2pix(inputShape, projectedPoints);

    cv::Size size = cv::Size(width, height);
    cv::Mat xPts = [self scaled:vectors::axis(0, imagePoints) size:size];
    cv::Mat yPts = [self scaled:vectors::axis(1, imagePoints) size:size];

    cv::Mat inputImage = [self.inputImage mat];
    cv::Mat outputImage;
    cv::remap(inputImage,
              outputImage,
              xPts,
              yPts,
              cv::INTER_CUBIC,
              BORDER_DEFAULT);

    return [[UIImage alloc] initWithCVMat:outputImage];
}

- (cv::Mat)scaled:(vector_d)axis size:(cv::Size)size {
    cv::Mat resized;
    cv::Mat converted;
    cv::resize(axis,
               resized,
               size, 0, 0,
               cv::INTER_CUBIC);
    resized.convertTo(converted, CV_32F);
    //logs::describe_vector(converted, "converted");
    cout << converted.size << " x " << converted.channels() << endl;

    return converted;
}

- (UIImage *)preCorrespondenceKeyPoints {
    std::vector<int> pts = self.numKeyPointsPerSpan;
    int npts = std::accumulate(pts.begin(), pts.end(), 0);
    cout << "   got " << pts.size() << " spans";
    cout << " with " << npts << " points." << endl;

    std::vector<cv::Point2d> keyPointIndexes = [self keyPointIndexes:self.numKeyPointsPerSpan];
    std::vector<cv::Point2d> dstpoints = [self destinationPoints:self.keyPoints];
    std::vector<double> parameters = self.defaultParameters;

    double params[parameters.size()];
    for (int i = 0; i < int(parameters.size()); i++) {
        params[i] = parameters[i];
    }
    std::vector<cv::Point2d> projectedPoints = self.projector->projectKeypoints(keyPointIndexes, params);
    return [self renderKeyPoints:projectedPoints destinations:dstpoints];
}

- (UIImage *)postCorresponenceKeyPoints {
    std::vector<cv::Point2d> keyPointIndexes = [self keyPointIndexes:self.numKeyPointsPerSpan];
    std::vector<cv::Point2d> dstpoints = [self destinationPoints:self.keyPoints];
    OptimizerResult res = [self optimizeImage];
    std::vector<double> parameters = res.x;
    double params[parameters.size()];
    for (int i = 0; i < int(parameters.size()); i++) {
        params[i] = parameters[i];
    }
    std::vector<cv::Point2d> projectedPoints = self.projector->projectKeypoints(keyPointIndexes, params);
    return [self renderKeyPoints:projectedPoints destinations:dstpoints];
}

- (UIImage *)renderKeyPoints:(std::vector<cv::Point2d>)keyPoints destinations:(std::vector<cv::Point2d>)dstPoints {
    cv::Mat display = [self.workingImage mat];
    cv::Size2d imgSize = cv::Size2d(self.workingImage.size.width, self.workingImage.size.height);
    std::vector<cv::Point2d> destinationPoints = vectors::norm2pix(imgSize, dstPoints);
    std::vector<cv::Point2d> projectedPoints = vectors::norm2pix(imgSize, keyPoints);
    assert(destinationPoints.size() == projectedPoints.size());

    int pointCnt = int(destinationPoints.size());
    cv::Scalar red = cv::Scalar(255, 0, 0);
    cv::Scalar blue = cv::Scalar(0, 0, 255);
    cv::Scalar white = cv::Scalar(255, 255, 255);
    for (int i = 0; i < pointCnt; i++) {
        cv::Point2d p1 = projectedPoints[i];
        cv::circle(display, p1, 3, red, -1, cv::LINE_AA);

        cv::Point2d p2 = destinationPoints[i];
        cv::circle(display, p2, 3, blue, -1, cv::LINE_AA);

        cv::line(display, p1, p2, white, 1, cv::LINE_AA);
    }

    return [[UIImage alloc] initWithCVMat:display];
}

- (OptimizerResult)optimizeImage {
    std::vector<cv::Point2d> keyPointIndexes = [self keyPointIndexes:self.numKeyPointsPerSpan];
    std::vector<cv::Point2d> dstpoints = [self destinationPoints:self.keyPoints];
    cv::Ptr<KeyPointCostFunction> fn = cv::Ptr<KeyPointCostFunction>(new KeyPointCostFunction(dstpoints, keyPointIndexes));
    Optimizer opt = Optimizer(fn, self.defaultParameters);

    printf("initial objective is %f\n",  opt.initialOptimization().fun);
    OptimizerResult res = opt.optimize();
    printf("optimization took: %f seconds\n", res.dur);
    printf("final objective is %f\n", res.fun);

    return res;
}

- (OptimizerResult)optimizeImageCornersWithOptimizedKeypoints:(std::vector<double>)keyPoints {
    std::vector<cv::Point2d> dstpoints = {cv::Point2d(self.corners.botRight.x, self.corners.botRight.y)};
    std::vector<double> params = {self.normalizedDimensions.width, self.normalizedDimensions.height};

    cv::Ptr<CornerPointCostFunction> fn = cv::Ptr<CornerPointCostFunction>(new CornerPointCostFunction(dstpoints, keyPoints));
    Optimizer opt = Optimizer(fn, params);

    printf("initial objective is %f\n",  opt.initialOptimization().fun);
    OptimizerResult res = opt.optimize();
    printf("optimization took: %f seconds\n", res.dur);
    printf("final objective is %f\n", res.fun);
    return res;
}

- (CGSize)normalizedDimensions {
    CGPoint w = geom::subtract(self.corners.topRight, self.corners.topLeft);
    CGPoint h = geom::subtract(self.corners.botLeft, self.corners.topLeft);
    double pageWidth = norm(geom::convertTo(w));
    double pageHeight = norm(geom::convertTo(h));
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
    std::vector<cv::Point2d> imagePoints = {
        geom::convertTo(self.corners.topLeft),
        geom::convertTo(self.corners.topRight),
        geom::convertTo(self.corners.botRight),
        geom::convertTo(self.corners.botLeft)
    };

    cv::Matx33d intrinsics = Matx<double, 3, 3>();
    intrinsics(0, 0) = 1.8;
    intrinsics(1, 1) = 1.8;
    intrinsics(0, 2) = 0.;
    intrinsics(1, 2) = 0.;
    intrinsics(2, 2) = 1.;

    // output rotation vectors
    std::vector<double> rvec;
    // output translation vectors
    std::vector<double> tvec;

    // estimate rotation and translation from four 2D-to-3D point correspondences
    cv::solvePnP(cornersObject3d,
                 imagePoints,
                 intrinsics,
                 cv::Mat::zeros(5, 1, cv::DataType<double>::type),
                 rvec,
                 tvec);

    // our initial guess for the cubic has no slope
    std::vector<double> cubicSlope = std::vector<double>({0.0, 0.0});

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
    for (int i = 0; i < self.yCoordinates->size(); i++) {
        params.push_back(self.yCoordinates->at(i));
    }
    for (int i = 0; i < self.xCoordinates->size(); i++) {
        std::vector<double> values = self.xCoordinates->at(i);
        for (int j = 0; j < values.size(); j++) {
            params.push_back(values[j]);
        }
    }
    return params;
}

- (std::vector<int>)numKeyPointsPerSpan {
    std::vector<int> counts;
    for (int i = 0; i < self.xCoordinates->size(); i++) {
        std::vector<double> values = self.xCoordinates->at(i);
        counts.push_back(int(values.size()));
    }
    return counts;
}

- (std::vector<cv::Point2d>)keyPointIndexes:(std::vector<int>)numKeyPointsPerSpan {
    int npts = std::accumulate(numKeyPointsPerSpan.begin(), numKeyPointsPerSpan.end(), 0);
    std::vector<std::vector<int>> keyPointIdx = std::vector<std::vector<int>>(2, std::vector<int>(npts+1, 0));
    int start = 1;
    for (int i = 0; i < numKeyPointsPerSpan.size(); i++) {
        int count = numKeyPointsPerSpan[i];
        int end = start + count;
        for (int r = start; r < end; r++) {
            keyPointIdx[1][r] = 8+i;
        }
        start = end;
    }

    for (int i = 0; i < npts; i++) {
        keyPointIdx[0][i+1] = i + 8 + int(numKeyPointsPerSpan.size());
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
- (EigenVector)eigenVector:(std::vector<vector<cv::Point2d>>)keyPoints {
    double eigenInit[] = {0, 0};
    double allWeights = 0.0;
    cv::Mat allEigenVectors = cv::Mat(1, 2, cv::DataType<double>::type, eigenInit);

    for (int i = 0; i < keyPoints.size(); i++) {
        std::vector<cv::Point2d> vectorPoints = keyPoints[i];
        cv::Mat computePoints = cv::Mat(vectorPoints).reshape(1);
        cv::PCA pca(computePoints, cv::Mat(), CV_PCA_USE_AVG, 1);

        cv::Point2d firstP = vectorPoints[0];
        cv::Point2d lastP = vectorPoints[vectorPoints.size() -1];
        cv::Point2d point = lastP - firstP;
        double weight = cv::norm(point);

        cv::Mat eigenMul = pca.eigenvectors.mul(weight);
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

- (std::vector<double>)normalizeOutline:(CGRectOutline)outline with:(CGPoint)eigenVector {
    cv::Point2d eigenVec = geom::convertTo(eigenVector);
    std::vector<cv::Point2d> pts = {
        geom::convertTo(outline.topLeft),
        geom::convertTo(outline.topRight),
        geom::convertTo(outline.botRight),
        geom::convertTo(outline.botLeft)
    };
    cv::Size2d size = cv::Size2d(outline.size.width, outline.size.height);
    std::vector<cv::Point2d> normalizedPts = vectors::pix2norm(size, pts);
    
    return vectors::dotProduct(normalizedPts, eigenVec);
}

- (CGRectOutline)outlineWithEigenVector:(EigenVector)eigenVector {
    double px0 = *std::min_element(self.pxCoords->begin(), self.pxCoords->end());
    double px1 = *std::max_element(self.pxCoords->begin(), self.pxCoords->end());
    double py0 = *std::min_element(self.pyCoords->begin(), self.pyCoords->end());
    double py1 = *std::max_element(self.pyCoords->begin(), self.pyCoords->end());
    cv::Point2d eigenVectorx = geom::convertTo(eigenVector.x);
    cv::Point2d eigenVectory = geom::convertTo(eigenVector.y);

    // from top left, clockwise
    cv::Point2d p00 = px0 * eigenVectorx + py0 * eigenVectory;
    cv::Point2d p01 = px1 * eigenVectorx + py0 * eigenVectory;
    cv::Point2d p11 = px1 * eigenVectorx + py1 * eigenVectory;
    cv::Point2d p10 = px0 * eigenVectorx + py1 * eigenVectory;

    return CGRectOutlineMake(geom::convertTo(p00),
                             geom::convertTo(p01),
                             geom::convertTo(p11),
                             geom::convertTo(p10));
}

- (std::vector<double>)generateCoordinatesY:(std::vector<std::vector<cv::Point2d>>)keyPoints withEigenVector:(EigenVector)eigenVector {
    cv::Point2d eigen = geom::convertTo(eigenVector.y);
    double py0 = *std::min_element(self.pyCoords->begin(), self.pyCoords->end());

    std::vector<double> results;
    for (int i = 0; i < keyPoints.size(); i++) {
        std::vector<cv::Point2d> spanPoints = keyPoints[i];
        std::vector<double> ycoords = vectors::dotProduct(spanPoints, eigen);
        double average = 1.0 * std::accumulate(ycoords.begin(), ycoords.end(), 0.0) / ycoords.size();
        results.push_back(average - py0);
    }
    return results;
}

- (std::vector<std::vector<double>>)generateCoordinatesX:(std::vector<std::vector<cv::Point2d>>)keyPoints withEigenVector:(EigenVector)eigenVector {
    cv::Point2d eigen = geom::convertTo(eigenVector.x);
    double px0 = *std::min_element(self.pxCoords->begin(), self.pxCoords->end());
    std::vector<std::vector<double>> results;
    for (int i = 0; i < keyPoints.size(); i++) {
        std::vector<cv::Point2d> spanPoints = keyPoints[i];
        std::vector<double> xCoords = vectors::dotProduct(spanPoints, eigen);
        results.push_back(vectors::subtract(xCoords, px0));
    }

    return results;
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
