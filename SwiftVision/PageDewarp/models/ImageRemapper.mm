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
#import "leptonica.hpp"
#import "types.h"
#import "print+extras.hpp"
#import "UIImage+Mat.h"
// optimization
#import "PtraArray.hpp"
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

typedef std::vector<cv::Point2d> vector_pointd;
typedef std::vector<std::vector<cv::Point2d>> vector_pointdd;

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
    // -------------
    // Constructor input
    // -------------
    // Sampled KeyPoints : vvectorPointD
    // Size of Image : DSize
    // -------------
    // -------------
    // Properties
    // -------------
    // Sampling frequency value : int
    // -------------
    // -------------

    cv::Mat display = [self.inputImage mat];
    cv::Scalar red = cv::Scalar(255, 0, 0);
    cv::Scalar blue = cv::Scalar(0, 0, 255);
    cv::Scalar black = cv::Scalar(0, 0, 0);
    cv::Scalar green = cv::Scalar(34, 139, 34);
    cv::Scalar yellow = cv::Scalar(255, 250, 205);

    bool debugv = false;
    bool debugh = true;

    DSize inSize = (DSize){ .width = self.inputImage.size.width, .height = self.inputImage.size.height };
    printf("inSize: {%f, %f}\n", inSize.width, inSize.height);
    vvectorPointD *ptaa = new vvectorPointD();
    for (int v = 0; v < self.keyPoints.size(); v++) {
        std::vector<cv::Point2d> ps = self.keyPoints.at(v);
        vectorPointD *pta = new vectorPointD();
        for (int c = 0; c < ps.size(); c++) {
            cv::Point2d p = ps.at(c);
            DPoint pt = (DPoint){ .x = p.x, .y = p.y };
            pta->push_back(pt);
        }
        vectorPointD normalizedPts = math::norm2pix(inSize, *pta);
        ptaa->push_back(normalizedPts);
    }
    int sampling = 40;
    int nx = (inSize.width + 2 * sampling - 2) / sampling;     // number of sampling pts in x-dir
    int ny = (inSize.height + 2 * sampling - 2) / sampling;     // number of sampling pts in y-dir
    int nlines = (int) ptaa->size();
    double c2, c1, c0;
    double val;
    int i, j;

    vvectorPointD *ptaa0 = new vvectorPointD();
    vectorD *nacurve0 = new vectorD();
    for (i = 0; i < nlines; i++) {  // take all the vertical center points for a line
        if (ptaa->at(i).size() < 3)
            continue;

        vectorPointD *pta = new vectorPointD((*ptaa)[i]);
        math::getQuadraticLSF(pta, &c2, &c1, &c0, NULL);        // calculate the LSF
        nacurve0->push_back(c2);                                // store the c2 coeffecient..
        vectorPointD *ptad = new vectorPointD();              // create a point array with a size = the number of

        double x, y = 0;
        for (j = 0; j < nx; j++) {                              // samples in the horizontal direction
            x = j * sampling;                                   // keep jumping forward by the sampling value...
            math::applyQuadraticFit(c2, c1, c0, x, &y);         // and run the quadratic fit, y is an out variable...
            DPoint p = (DPoint){.x = x, .y = y};
            ptad->push_back(p);                 // and store x and y in the ptad

            if (debugv)
                cv::circle(display, cv::Point2d(x, y), 12, blue, -1, cv::LINE_AA);
        }
        ptaa0->push_back(*ptad);
        free(ptad);
        free(pta);
    }
//    free(ptaa);
    nlines = (int) ptaa0->size();

    /* Remove lines with outlier curvatures.
     * Note that this is just looking for internal consistency in
     * the line curvatures. */
    double medvar;
    double medval;
    leptonica::getMedianVariation(nacurve0, &medval, &medvar);
    vvectorPointD *ptaa1 = new vvectorPointD();
    vectorD *nacurve1 = new vectorD();

    for (i = 0; i < nlines; i++) {  /* for each line */
        val = nacurve0->at(i);
        if (ABSX(val - medval) > 7.0 * medvar)
            continue;
        vectorPointD *pta = new vectorPointD((*ptaa0)[i]);
        ptaa1->push_back(*pta);
        nacurve1->push_back(val);
        free(pta);
    }
    nlines = (int)ptaa1->size();
    free(nacurve0);

    /**
     * TODO: calculate and store the min and max curvature (from nacurve1)
     *
     */

    /* Find and save the y values at the mid-points in each curve.
     * If the slope is zero anywhere, it will typically be here. */
    vectorD *namidy = new vectorD();
    for (i = 0; i < nlines; i++) {
        vectorPointD *pta = new vectorPointD((*ptaa1)[i]);
        int npts = (int)pta->size();
        DPoint mid = pta->at(npts/2);
        namidy->push_back(mid.y);
        if (debugv) {
            cv::circle(display, cv::Point(mid.x, mid.y), 20, red, -1, cv::LINE_AA);
            cv::line(display, cv::Point(0, mid.y), cv::Point(inSize.width, mid.y), black, 5, cv::LINE_AA);
        }
        free(pta);
    }

    /**
     * Sort the lines in ptaa1 by their vertical position, going down
     */
    vectorD *namidysi = leptonica::getSortIndex(namidy, L_SORT_INCREASING);
    vectorD *namidys = leptonica::sortByIndex(namidy, namidysi);
    vectorD *nacurves = leptonica::sortByIndex(nacurve1, namidysi);
    vvectorPointD *ptaa2 = leptonica::sortByIndex(ptaa1, namidysi);
    free(namidy);
    free(nacurve1);
    free(namidysi);
    free(nacurves);

    /* Convert the sampled points in ptaa2 to a sampled disparity with
     * with respect to the y value at the mid point in the curve.
     * The disparity is the distance the point needs to move;
     * plus is downward.  */
    vvectorPointD *ptaa3 = new vvectorPointD();
    for (i = 0; i < nlines; i++) {
        vectorPointD *pta = new vectorPointD((*ptaa2)[i]);
        vectorPointD *ptad = new vectorPointD();
        double midy = namidys->at(i);

        for (j = 0; j < nx; j++) {
            DPoint p = pta->at(j);
            DPoint disparity = (DPoint){.x = p.x, .y = midy - p.y};
            ptad->push_back(disparity);

            if (debugv) {
                cv::circle(display, cv::Point(p.x, p.y), 10, red, -1, cv::LINE_AA);
            }
        }
        ptaa3->push_back(*ptad);
        free(pta);
        free(ptad);
    }

    /* Generate ptaa4 by taking vertical 'columns' from ptaa3.
     * We want to fit the vertical disparity on the column to the
     * vertical position of the line, which we call 'y' here and
     * obtain from namidys.  So each pta in ptaa4 is the set of
     * vertical disparities down a column of points.  The columns
     * in ptaa4 are equally spaced in x. */
    vvectorPointD *ptaa4 = new vvectorPointD();
    vectorD *famidys = new vectorD(*namidys);
    for (j = 0; j < nx; j++) {
        vectorPointD *pta = new vectorPointD();
        for (i = 0; i < nlines; i++) {
            double y = (*famidys)[i];
            DPoint p = (*ptaa3)[i][j];
            DPoint op = (DPoint){.x = y, .y = p.y};
            pta->push_back(op);
        }
        ptaa4->push_back(*pta);
        free(pta);
    }
    free(namidys);

    /* Do quadratic fit vertically on each of the pixel columns
     * in ptaa4, for the vertical displacement (which identifies the
     * src pixel(s) for each dest pixel) as a function of y (the
     * y value of the mid-points for each line).  Then generate
     * ptaa5 by sampling the fitted vertical displacement on a
     * regular grid in the vertical direction.  Each pta in ptaa5
     * gives the vertical displacement for regularly sampled y values
     * at a fixed x. */
    vvectorPointD *ptaa5 = new vvectorPointD();  /* uniformly sampled across full height of image */
    for (j = 0; j < nx; j++) {  /* for each column */
        vectorPointD *pta = new vectorPointD((*ptaa4)[j]);
        math::getQuadraticLSF(pta, &c2, &c1, &c0, NULL);
        vectorPointD *ptad = new vectorPointD();
        for (i = 0; i < ny; i++) {  /* uniformly sampled in y */
            int y = i * sampling;
            double val;
            math::applyQuadraticFit(c2, c1, c0, y, &val);
            DPoint p = (DPoint){.x = (double)y, .y = val};
            ptad->push_back(p);
        }
        //logs::describe_vector(*ptad, "ptad");
        ptaa5->push_back(*ptad);
        free(ptad);
        free(pta);
    }

    vvectorPointD *pix = new vvectorPointD();
    for (i = 0; i < ny; i++) {
        vectorPointD *row = new vectorPointD();
        for (j = 0; j < nx; j++) {
            DPoint p = ptaa5->at(j).at(i);
            row->push_back(p);
        }
        //logs::describe_vector(*row, "row");
        pix->push_back(*row);
        free(row);
    }

    cv::Mat fpix = cv::Mat(nx, ny, cv::DataType<cv::Point2d>::type);
    for (i = 0; i < ny; i++) {
        for (j = 0; j < nx; j++) {
            DPoint p = (*ptaa5)[j][i];
            fpix.at<cv::Point2d>(j, i) = cv::Point2d(p.x, p.y);
        }
    }

    free(famidys);
    free(ptaa0);
    free(ptaa1);
    free(ptaa2);
    free(ptaa3);
    free(ptaa4);
    free(ptaa5);











    /**
     * GetLineEndPoints
     */

    vectorPointD *pptal, *pptar; /* the output */
    vectorPointD *ptal1, *ptar1;  /* left/right end points of lines; initial */
    vectorPointD *ptal2, *ptar2;  /* left/right end points; after filtering */
    vectorPointD *ptal3, *ptar3;  /* left and right block, fitted, uniform spacing */
    vectorD      *nald, *nard;

    int n = (int)ptaa->size();
    /* Extract the line end points, and transpose x and y values */
    ptal1 = new vectorPointD();
    ptar1 = new vectorPointD();
    for (i = 0; i < n; i++) {
        vectorPointD *pta = new vectorPointD((*ptaa)[i]);
        DPoint p1 = pta->at(0);
        DPoint tp1 = (DPoint){ .x = p1.y, .y = p1.x};  /* transpose */
        ptal1->push_back(tp1);

        int npt = (int)pta->size();
        DPoint p2 = pta->at(npt-1);
        DPoint tp2 = (DPoint){ .x = p2.y, .y = p2.x};  /* transpose */
        ptar1->push_back(tp2);

        free(pta);

        if (debugh) {
            cv::circle(display, cv::Point(tp1.y, tp1.x), 12, yellow, -1, cv::LINE_AA);
            cv::circle(display, cv::Point(tp2.y, tp2.x), 12, yellow, -1, cv::LINE_AA);
        }
    }

    /*
     * TODO: Use the min and max of the y value on the left side!
     */

    /* Sort from top to bottom */
    pptal = leptonica::sort(ptal1, L_SORT_BY_X, L_SORT_INCREASING, NULL);
    pptar = leptonica::sort(ptar1, L_SORT_BY_X, L_SORT_INCREASING, NULL);

    /* Filter the points by x-location to prevent 2-column images
     * from getting confused about left and right endpoints. We
     * require valid left points to not be farther than
     *     0.20 * (remaining distance to the right edge of the image)
     * to the right of the leftmost endpoint, and similarly for
     * the right endpoints. (Note: x and y are reversed in the pta.)
     * Also require end points to be near the medians in the
     * upper and lower halves. */
    //ret = dewarpFilterLineEndPoints(dew, ptal1, ptar1, &ptal2, &ptar2);
    ptal2 = new vectorPointD(*ptal1);
    ptar2 = new vectorPointD(*ptar1);
    free(ptal1);
    free(ptar1);

    /* Do a quadratic fit to the left and right endpoints of the
     * longest lines.  Each line is represented by 3 coefficients:
     *     x(y) = c2 * y^2 + c1 * y + c0.
     * Using the coefficients, sample each fitted curve uniformly
     * along the full height of the image. */
    double mederr, cl0, cl1, cl2, cr0, cr1, cr2;
    double x, y, refl, refr;

    math::dewarpQuadraticLSF(ptal2, &cl2, &cl1, &cl0, &mederr);
    ptal3 = new vectorPointD();
    for (i = 0; i < ny; i++) {  /* uniformly sampled in y */
        y = i * sampling;
        math::applyQuadraticFit(cl2, cl1, cl0, y, &x);
        DPoint cp = (DPoint){.x = x, .y = y};
        ptal3->push_back(cp);
    }

    /* Fit the right side in the same way. */
    math::dewarpQuadraticLSF(ptar2, &cr2, &cr1, &cr0, &mederr);
    ptar3 = new vectorPointD();
    for (i = 0; i < ny; i++) {  /* uniformly sampled in y */
        y = i * sampling;
        math::applyQuadraticFit(cr2, cr1, cr0, y, &x);
        DPoint cp = (DPoint){.x = x, .y = y};
        ptar3->push_back(cp);
    }

    /* Find the x value at the midpoints (in y) of the two vertical lines,
     * ptal3 and ptar3.  These are the reference values for each of the
     * lines.  Then use the difference between the these midpoint
     * values and the actual x coordinates of the lines to represent
     * the horizontal disparity (nald, nard) on the vertical lines
     * for the sampled y values. */
    refl = ptal3->at(ny/2).x;
    refr = ptar3->at(ny/2).x;
    nald = new std::vector<double>();
    nard = new std::vector<double>();
    for (i = 0; i < ny; i++) {
        DPoint pl = ptal3->at(i);
        nald->push_back(refl-pl.x);

        DPoint pr = ptar3->at(i);
        nard->push_back(refr-pr.x);

        if (debugh) {
            cv::circle(display, cv::Point(pl.x, pl.y), 20, red, -1, cv::LINE_AA);
            cv::circle(display, cv::Point(pr.x, pr.y), 20, red, -1, cv::LINE_AA);
        }
    }

    if (debugh) {
        cv::line(display, cv::Point(refl, 0), cv::Point(refl, inSize.height), black, 5, cv::LINE_AA);
        cv::line(display, cv::Point(refr, 0), cv::Point(refr, inSize.height), black, 5, cv::LINE_AA);
    }

    /* Now for each pair of sampled values of the two lines (at the
     * same value of y), do a linear interpolation to generate
     * the horizontal disparity on all sampled points between them.  */
    vvectorPointD *ptaah = new vvectorPointD();
    for (i = 0; i < ny; i++) {
        vectorPointD *pta = new vectorPointD();
        val = nald->at(i);
        pta->push_back((DPoint){.x = refl, .y = val});
        val = nard->at(i);
        pta->push_back((DPoint){.x = refr, .y = val});

        math::getLinearLSF(pta, &c1, &c0, NULL);  /* horiz disparity along line */
        vectorPointD *ptat = new vectorPointD();
        for (j = 0; j < nx; j++) {
            x = j * sampling;
            math::applyLinearFit(c1, c0, x, &val);
            ptat->push_back((DPoint){.x = x, .y = val});
        }
        ptaah->push_back(*ptat);
        free(pta);
    }
    free(nald);
    free(nard);

    // construct output!

    free(ptal2);
    free(ptar2);
    free(ptal3);
    free(ptar3);
    free(ptaah);

    return [[UIImage alloc] initWithCVMat:display];
}

- (UIImage *)_remap {
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
    cv::Mat xPts = [self scale:vectors::axis(0, imgPts) from:cv::Size(xsize, ysize) to:size];
    cv::Mat yPts = [self scale:vectors::axis(1, imgPts) from:cv::Size(xsize, ysize) to:size];

    cv::Mat outputImage;
    cv::remap([self.inputImage mat],
              outputImage,
              xPts,
              yPts,
              cv::INTER_CUBIC,
              cv::BORDER_REPLICATE);

    return [[UIImage alloc] initWithCVMat:outputImage];
}

- (cv::Mat)scale:(vector_d)axis from:(cv::Size)from to:(cv::Size)size {
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
