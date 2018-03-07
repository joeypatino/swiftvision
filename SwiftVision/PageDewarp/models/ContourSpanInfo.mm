#import <opencv2/opencv.hpp>
#import "ContourSpanInfo.h"
// structs
#import "CGRectOutline.h"
// extras
#import "functions.h"

using namespace std;
using namespace cv;

@implementation ContourSpanInfo
- (instancetype)initWithCorners:(CGRectOutline)corners
                            xCoordinates:(NSArray <NSArray <NSNumber *> *> *)xCoordinates
                            yCoordinates:(NSArray <NSNumber *> *)yCoordinates {
    self = [super init];
    _corners = corners;
    _xCoordinates = xCoordinates;
    _yCoordinates = yCoordinates;
    return self;
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

- (CGSize)roughDimensions {
    NSLog(@"%s - %@", __PRETTY_FUNCTION__, self);
    CGPoint w = geom::subtract(self.corners.topRight, self.corners.topLeft);
    CGPoint h = geom::subtract(self.corners.botLeft, self.corners.topLeft);
    double pageWidth = norm(Mat(geom::convertTo(w)));
    double pageHeight = norm(Mat(geom::convertTo(h)));
    return CGSizeMake(pageHeight, pageWidth);
}

- (void)defaultParmeters {
    CGSize dimensions = self.roughDimensions;

    // Array of object points in the object coordinate space
    vector<Point3f> cornersObject3d = {
        Point3f(0, 0, 0),
        Point3f(dimensions.width, 0, 0),
        Point3f(dimensions.width, dimensions.height, 0),
        Point3f(0, dimensions.height, 0)};
    logs::describe_vector(cornersObject3d, "cornersObject3d");

    // Array of corresponding image points
    vector<Point2f> imagePoints = nsarray::convertTo(nsarray::pointsFrom(self.corners));
    logs::describe_vector(imagePoints, "imagePoints");

    // Input camera matrix
    float FOCAL_LENGTH = 1.8;
    vector<Point3f> camera = { Point3f(FOCAL_LENGTH, 0, 0),
        Point3f(0, FOCAL_LENGTH, 0),
        Point3f(0, 0, 1) };
    logs::describe_vector(camera, "camera");

    // Input vector of distortion coefficients
    vector<float> distanceCoeffs = {0.0, 0.0, 0.0, 0.0, 0.0};

    // output rotation vectors
    Mat rvec;
    // output translation vectors
    Mat tvec;
    // estimate rotation and translation from four 2D-to-3D point correspondences
    solvePnP(cornersObject3d, imagePoints, Mat(3, 3, CV_32F, &camera), Mat(5, 1, CV_32F, &distanceCoeffs), rvec, tvec);

    logs::describe_vector(rvec, "rvec");
    logs::describe_vector(tvec, "tvec");

    // our initial guess for the cubic has no slope
    vector<float> cubicSlope = vector<float>({0.0, 0.0});

    Mat params = Mat();
    params.push_back(rvec);
    params.push_back(tvec);
    params.push_back(cubicSlope);

    for (NSNumber *number in self.yCoordinates) {
        params.push_back(number.floatValue);
    }

    for (NSArray <NSNumber *> *numbers in self.xCoordinates) {
        for (NSNumber *number in numbers) {
            params.push_back(number.floatValue);
        }
    }

    logs::describe_vector(params, "params");
}

- (void)destinationPoints {

}
@end
