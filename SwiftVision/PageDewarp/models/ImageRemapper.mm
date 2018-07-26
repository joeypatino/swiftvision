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
    int REMAP_DECIMATE = 16;

    vector_d parameters = [self optimizeImage].x;
    OptimizerResult copt = [self optimizeImageCornersWithOptimizedKeypoints:parameters];
    cv::Size2d optimizedDims = cv::Size2d(copt.x[0], copt.x[1]);

    int height = math::round(0.5 * optimizedDims.height * 1.0 * self.inputImage.size.height, REMAP_DECIMATE);
    int width = math::round(height * optimizedDims.width / optimizedDims.height, REMAP_DECIMATE);
    cout << "  output will be {" << width << "x" << height << "}" << endl;

    int heightSmall = height / REMAP_DECIMATE;
    int widthSmall = width / REMAP_DECIMATE;

    vector_d xRng = math::linspace(0, optimizedDims.width, widthSmall);
    vector_d yRng = math::linspace(0, optimizedDims.height, heightSmall);

    int xsize = int(xRng.size());
    int ysize = int(yRng.size());
    vector_dd meshX = vector_dd(ysize, vector_d(xsize, 0));
    vector_dd meshY = vector_dd(ysize, vector_d(xsize, 0));
    vectors::meshgrid(xRng, yRng, &meshX, &meshY);

    vector_dd flatX = vectors::reshape(meshX, int(meshX.size()), 1);
    vector_dd flatY = vectors::reshape(meshY, int(meshY.size()), 1);
    vector_dd xy = vectors::hstack(flatX, flatY);

    cv::Size inputShape = cv::Size(self.inputImage.size.width, self.inputImage.size.height);
    std::vector<cv::Point2d> prjtdPts = self.projector->projectXY(xy, parameters.data());
    std::vector<cv::Point2d> imgPts = vectors::norm2pix(inputShape, prjtdPts);

    cv::Size size = cv::Size(width, height);
    cv::Mat xPts = [self scale:vectors::axis(0, imgPts) from:cv::Size(xsize, ysize) size:size];
    cv::Mat yPts = [self scale:vectors::axis(1, imgPts) from:cv::Size(xsize, ysize) size:size];

    cv::Mat outputImage;
    cv::remap([self.inputImage mat],
              outputImage,
              xPts,
              yPts,
              cv::INTER_CUBIC,
              cv::BORDER_REPLICATE);

    return [[UIImage alloc] initWithCVMat:outputImage];
}

- (cv::Mat)scale:(vector_d)axis from:(cv::Size)from size:(cv::Size)size {
    cv::Mat base = cv::Mat::zeros(from.height, from.width, cv::DataType<double>::type);
    int i = 0;
    for (int r = 0; r < from.height; r++) {
        for (int c = 0; c < from.width; c++) {
            base.at<double>(r, c) = axis[i];
            i++;
        }
    }
    cv::Mat resized;
    cv::resize(base,
               resized,
               size, 0, 0,
               cv::INTER_CUBIC);
    resized.convertTo(resized, CV_32F);
    return resized;
}

- (UIImage *)preCorrespondenceKeyPoints {
    std::vector<int> pts = self.numKeyPointsPerSpan;
    int npts = std::accumulate(pts.begin(), pts.end(), 0);
    cout << "   got " << pts.size() << " spans";
    cout << " with " << npts << " points." << endl;

    std::vector<cv::Point2d> keyPointIndexes = [self keyPointIndexes:self.numKeyPointsPerSpan];
    std::vector<cv::Point2d> dstpoints = [self destinationPoints:self.keyPoints];
    std::vector<double> parameters = self.defaultParameters;
    std::vector<cv::Point2d> projectedPoints = self.projector->projectKeypoints(keyPointIndexes, parameters.data());
    return [self renderKeyPoints:projectedPoints destinations:dstpoints];
}

- (UIImage *)postCorresponenceKeyPoints {
    std::vector<int> pts = self.numKeyPointsPerSpan;
    int npts = std::accumulate(pts.begin(), pts.end(), 0);
    cout << "   got " << pts.size() << " spans";
    cout << " with " << npts << " points." << endl;

    std::vector<cv::Point2d> keyPointIndexes = [self keyPointIndexes:self.numKeyPointsPerSpan];
    std::vector<cv::Point2d> dstpoints = [self destinationPoints:self.keyPoints];
    OptimizerResult res = [self optimizeImage];
    std::vector<double> parameters = res.x;
    std::vector<cv::Point2d> projectedPoints = self.projector->projectKeypoints(keyPointIndexes, parameters.data());
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
        cv::circle(display, destinationPoints[i], 3, blue, -1, cv::LINE_AA);
        cv::circle(display, projectedPoints[i], 3, red, -1, cv::LINE_AA);
        cv::line(display, projectedPoints[i], destinationPoints[i], white, 1, cv::LINE_AA);
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
    cv::Matx43d cornersObject3d = Matx<double, 4, 3>();
    cornersObject3d(0, 0) = 0;
    cornersObject3d(0, 1) = 0;
    cornersObject3d(0, 2) = 0;

    cornersObject3d(1, 0) = dimensions.width;
    cornersObject3d(1, 1) = 0;
    cornersObject3d(1, 2) = 0;

    cornersObject3d(2, 0) = dimensions.width;
    cornersObject3d(2, 1) = dimensions.height;
    cornersObject3d(2, 2) = 0;

    cornersObject3d(3, 0) = 0;
    cornersObject3d(3, 1) = dimensions.height;
    cornersObject3d(3, 2) = 0;

    // Array of corresponding image points
    std::vector<cv::Point2d> imagePoints = {
        geom::convertTo(self.corners.topLeft),
        geom::convertTo(self.corners.topRight),
        geom::convertTo(self.corners.botRight),
        geom::convertTo(self.corners.botLeft)
    };

    cv::Matx33d intrinsics = self.projector->cameraIntrinsics();

    // output rotation vectors
    std::vector<double> rvec;
    // output translation vectors
    std::vector<double> tvec;

    // estimate rotation and translation from four 2D-to-3D point correspondences
    cv::solvePnP(cornersObject3d,
                 imagePoints,
                 intrinsics,
                 cv::Mat::zeros(1, 5, cv::DataType<double>::type),
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
        cv::PCA pca(computePoints, cv::noArray(), CV_PCA_DATA_AS_ROW, 1);

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
    std::vector<cv::Point> pts = {
        cv::Point(geom::convertTo(outline.topLeft)),
        cv::Point(geom::convertTo(outline.topRight)),
        cv::Point(geom::convertTo(outline.botRight)),
        cv::Point(geom::convertTo(outline.botLeft))
    };

    cv::Mat p = cv::Mat(pts, cv::DataType<cv::Point>::type);
    cv::Mat pageCoords;
    cv::convexHull(p, pageCoords);

    std::vector<cv::Point2d> hullpts;
    for (int c = 0; c < pageCoords.cols; c++) {
        for (int r = 0; r < pageCoords.rows; r++) {
            hullpts.push_back(pageCoords.at<cv::Point>(c, r));
        }
    }

    cv::Size2d size = cv::Size2d(self.workingImage.size.width, self.workingImage.size.height);
    std::vector<cv::Point2d> normalizedPts = vectors::pix2norm(size, hullpts);

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
@end
