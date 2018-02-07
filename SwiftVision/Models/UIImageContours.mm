#import "UIImageContours.h"
#import "UIImage+Mat.h"
#import "UIImage+OpenCV.h"

using namespace std;

@interface Contour ()
- (instancetype)initWithCVMat:(cv::Mat)cvMat;
@property (nonatomic, assign) cv::Mat mat;
@end

@interface UIImageContours ()
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, strong) NSArray<Contour *> *contours;
@property (nonatomic, assign) cv::Mat inputImage;
@end

@implementation UIImageContours
- (instancetype)initWithImage:(UIImage *)image {
    self = [super init];
    self.image = [[self masked: image] copy];
    self.inputImage = [self.image mat];
    self.contours = [self processContours: self.inputImage];

    return self;
}

- (UIImage *)masked:(UIImage *)img {
    UIImage *thresh = [img threshold:55.0 constant:25.0];
    UIImage *dilate = [thresh dilate:CGSizeMake(14, 1)];
    UIImage *erode = [dilate erode:CGSizeMake(1, 5)];

    return [erode elementwiseMinimum:thresh];
}

- (NSInteger)count {
    return self.contours.count;
}

- (Contour *)objectAtIndexedSubscript:(NSInteger)idx {
    return self.contours[idx];
}

#pragma MARK -

- (NSArray<Contour *> *)processContours:(cv::Mat)cvMat {
    vector<vector<cv::Point> > contours;
    cv::Mat inputImage;
    cv::cvtColor(cvMat, inputImage, CV_RGB2GRAY);
    cv::findContours(inputImage, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);

    NSMutableArray <Contour *> *foundContours = @[].mutableCopy;

    cv::Mat outImage = cv::Mat(contours);
    for (int j = 0; j < outImage.total(); j++) {
        cv::Mat c = cv::Mat(outImage.at<vector<cv::Point>>(j));
        if (c.empty()) continue;

        Contour *cc = [[Contour alloc] initWithCVMat:c];
        [foundContours addObject:cc];
    }
    return foundContours;
}

- (UIImage *)renderedContours {
    cv::Mat outImage = cv::Mat::zeros(self.image.size.height, self.image.size.width, CV_8UC3);
    [self.contours enumerateObjectsUsingBlock:^(Contour *contour, NSUInteger idx, BOOL *stop) {
        cv::drawContours(outImage, contour.mat, -1, cv::Scalar(255, 0, 0), -1);
    }];
    return [[UIImage alloc] initWithCVMat:outImage];
}

@end
