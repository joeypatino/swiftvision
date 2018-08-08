#import <opencv2/opencv.hpp>
#import "DisparityModel.h"
// extras
#import "UIImage+Mat.h"
#import "math.hpp"
#import "dewarp.hpp"

using namespace cv;

@implementation DisparityModel
- (instancetype)initWithImage:(UIImage *)image keyPoints:(std::vector<vector<Point2d>>)keyPoints {
    self = [super init];
    _inputImage = image;
    _keyPoints = keyPoints;
    return self;
}

- (void)dealloc {
}

- (UIImage *_Nullable)apply {
    return [self apply:DewarpOutputDewarped];
}

- (UIImage *_Nullable)apply:(DewarpOutput)options {
    Mat inImage = [self.inputImage mat];
    Mat outImage = inImage.clone();

    DSize inSize = (DSize){
        .width = (double)inImage.cols,
        .height = (double)inImage.rows
    };
    vvectorPointD *txtLinePts = [self convertKeypoints:self.keyPoints];
    int w, h, d, i, j;
    int sampling = 20;
    int grayin = -1;
    d = inImage.channels();
    w = inSize.width;
    h = inSize.height;

    /**
     * Debugging output
     */
    vvectorPointD *vQuadraticCurvePoints = NULL;
    vectorPointD *vCurveCenterPoints = NULL;
    /** <-------------> */

    /**
     * apply the vertical disparity map
     **/
    vvectorD *vDisparity = [self getVerticalDisparity:txtLinePts
                                       inputImageSize:inSize
                                     samplinginterval:sampling
                                 quadraticCurvePoints:&vQuadraticCurvePoints
                                    curveCenterPoints:&vCurveCenterPoints];
    int isrc;
    for(i = 0; i < h && (options & DewarpOutputDewarped); i++) {
        int wpl = w * d;

        for(j = 0; j < wpl; j++) {
            isrc = (int)(i - vDisparity->at(i).at(j/d) + 0.5);

            if (grayin < 0)
                isrc = min(max(isrc, 0), h - 1);
            if (isrc >= 0 && isrc < h){
                unsigned char *rowPtr = inImage.ptr(isrc);
                outImage.at<unsigned char>(i, j) = rowPtr[j];
            }
        }
    }

    [self debugVerticals:outImage
    quadraticCurvePoints:(options & DewarpOutputVerticalQuadraticCurves) ? vQuadraticCurvePoints : NULL
       curveCenterPoints:(options & DewarpOutputVerticalCenterLines) ? vCurveCenterPoints : NULL];

    return [[UIImage alloc] initWithCVMat:outImage];
}

- (vvectorPointD *)convertKeypoints:(std::vector<vector<Point2d>>)keyPoints {
    vvectorPointD *ptaa = new vvectorPointD();
    for (int v = 0; v < keyPoints.size(); v++) {
        std::vector<Point2d> ps = keyPoints.at(v);
        vectorPointD *pta = new vectorPointD();
        for (int c = 0; c < ps.size(); c++) {
            Point2d p = ps.at(c);
            DPoint pt = (DPoint){ .x = p.x, .y = p.y };
            pta->push_back(pt);
        }
        ptaa->push_back(*pta);
    }
    return ptaa;
}

- (vvectorD *)scaleDisparity:(vvectorD *)disparity
              inputImageSize:(DSize)inSize
            samplingInterval:(int)sampling {

    vvectorD *fulldisparity;
    vvectorD *fpixt1, *fpixt2;
    int deltaw, deltah, redfactor;
    int nx, ny;

    /* Find the required width and height expansion deltas */
    redfactor = 1;
    nx = (inSize.width + 2 * sampling - 2) / sampling;      // number of sampling pts in x-dir
    ny = (inSize.height + 2 * sampling - 2) / sampling;     // number of sampling pts in y-dir
    deltaw = inSize.width - sampling * (nx - 1) + 2;
    deltah = inSize.height - sampling * (ny - 1) + 2;
    deltaw = redfactor * max(0, deltaw);
    deltah = redfactor * max(0, deltah);

    /* Generate the full res vertical array if it doesn't exist,
     * extending it as required to make it big enough.  Use x,y
     * to determine the amounts on each side. */
    fpixt1 = new vvectorD(*disparity);
    if (redfactor == 2)
        dewarp::addMultConstant(fpixt1, 0.0, (double)redfactor);

    fpixt2 = dewarp::scaleByInteger(fpixt1, sampling * redfactor);
    fulldisparity = new vvectorD(*fpixt2);
    free(fpixt1);
    free(fpixt2);

    return fulldisparity;
}

- (vvectorD *)getHorizontalDisparity:(vvectorPointD *)keypoints
                      inputImageSize:(DSize)inSize
                    samplinginterval:(int)sampling {
    return [self getHorizontalDisparity:keypoints
                         inputImageSize:inSize
                       samplinginterval:sampling
                   quadraticCurvePoints:NULL
                   quadraticCurvePoints:NULL
                      leftLineEndPoints:NULL
                     rightLineEndPoints:NULL
                             leftBounds:NULL
                            rightBounds:NULL];
}

- (vvectorD *)getHorizontalDisparity:(vvectorPointD *)keypoints
                      inputImageSize:(DSize)inSize
                    samplinginterval:(int)sampling
                quadraticCurvePoints:(vectorPointD **)leftQuadraticCurvePoints
                quadraticCurvePoints:(vectorPointD **)rightQuadraticCurvePoints
                   leftLineEndPoints:(vectorPointD **)leftLineEndPoints
                  rightLineEndPoints:(vectorPointD **)rightLineEndPoints
                          leftBounds:(double *)leftBounds
                         rightBounds:(double *)rightBounds {

    vectorPointD *ptal1, *ptar1;  /* left/right end points of lines; initial */
    vectorPointD *ptal2, *ptar2;  /* left/right end points; after filtering */
    vectorPointD *ptal3, *ptar3;  /* left and right block, fitted, uniform spacing */
    vectorPointD *pptal, *pptar;
    vectorD *nald, *nard;
    double val, c1, c0;
    int n, i, j;
    int nx, ny;

    nx = (inSize.width + 2 * sampling - 2) / sampling;     // number of sampling pts in x-dir
    ny = (inSize.height + 2 * sampling - 2) / sampling;     // number of sampling pts in y-dir
    n = (int)keypoints->size();
    ptal1 = new vectorPointD();
    ptar1 = new vectorPointD();

    /* Extract the line end points, and transpose x and y values */
    for (i = 0; i < n; i++) {
        vectorPointD *pta = new vectorPointD((*keypoints)[i]);
        DPoint p1 = pta->at(0);
        DPoint tp1 = (DPoint){ .x = p1.y, .y = p1.x};  /* transpose */
        ptal1->push_back(tp1);

        int npt = (int)pta->size();
        DPoint p2 = pta->at(npt-1);
        DPoint tp2 = (DPoint){ .x = p2.y, .y = p2.x};  /* transpose */
        ptar1->push_back(tp2);

        free(pta);
    }

    if (leftLineEndPoints) {
        *leftLineEndPoints = NULL;
        *leftLineEndPoints = new vectorPointD(*ptal1);
    }
    if (rightLineEndPoints) {
        *rightLineEndPoints = NULL;
        *rightLineEndPoints = new vectorPointD(*ptar1);
    }

    /*
     * TODO: Use the min and max of the y value on the left side!
     */

    /* Sort from top to bottom */
    pptal = dewarp::sort(ptal1, L_SORT_BY_X, L_SORT_INCREASING, NULL);
    pptar = dewarp::sort(ptar1, L_SORT_BY_X, L_SORT_INCREASING, NULL);

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
    if (leftQuadraticCurvePoints) {
        *leftQuadraticCurvePoints = NULL;
        *leftQuadraticCurvePoints = new vectorPointD(*ptal3);
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
    if (rightQuadraticCurvePoints) {
        *rightQuadraticCurvePoints = NULL;
        *rightQuadraticCurvePoints = new vectorPointD(*ptar3);
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
    }
    if (leftBounds) {
        *leftBounds = NULL;
        *leftBounds = refl;
    }
    if (rightBounds) {
        *rightBounds = NULL;
        *rightBounds = refr;
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

    vvectorD *hdisparity = new vvectorD(ny, vectorD(nx, 0));
    for (i = 0; i < ny; i++) {
        for (j = 0; j < nx; j++) {
            hdisparity->at(i).at(j) = ptaah->at(i).at(j).y;
        }
    }

    free(ptal2);
    free(ptar2);
    free(ptal3);
    free(ptar3);
    free(ptaah);

    return [self scaleDisparity:hdisparity inputImageSize:inSize samplingInterval:sampling];
}

- (vvectorD *)getVerticalDisparity:(vvectorPointD *)keypoints
                    inputImageSize:(DSize)inSize
                  samplinginterval:(int)sampling {
    return [self getHorizontalDisparity:keypoints
                         inputImageSize:inSize
                       samplinginterval:sampling
                   quadraticCurvePoints:NULL
                   quadraticCurvePoints:NULL
                      leftLineEndPoints:NULL
                     rightLineEndPoints:NULL
                             leftBounds:NULL
                            rightBounds:NULL];
}

- (vvectorD *)getVerticalDisparity:(vvectorPointD *)keypoints
                    inputImageSize:(DSize)inSize
                  samplinginterval:(int)sampling
              quadraticCurvePoints:(vvectorPointD **)quadraticCurvePoints
                 curveCenterPoints:(vectorPointD **)curveCenterPoints {
    double val, c2, c1, c0;
    int i, j;
    int nx, ny;
    int nlines;

    nx = (inSize.width + 2 * sampling - 2) / sampling;     // number of sampling pts in x-dir
    ny = (inSize.height + 2 * sampling - 2) / sampling;     // number of sampling pts in y-dir
    nlines = (int) keypoints->size();

    vvectorPointD *ptaa0 = new vvectorPointD();
    vectorD *nacurve0 = new vectorD();
    for (i = 0; i < nlines; i++) {  // take all the vertical center points for a line
        if (keypoints->at(i).size() < 3)
            continue;

        vectorPointD *pta = new vectorPointD((*keypoints)[i]);
        math::getQuadraticLSF(pta, &c2, &c1, &c0, NULL);        // calculate the LSF
        nacurve0->push_back(c2);                                // store the c2 coeffecient..
        vectorPointD *ptad = new vectorPointD();                // create a point array with a size = the number of

        double x, y = 0;
        for (j = 0; j < nx; j++) {                          // samples in the horizontal direction
            x = j * sampling;                               // keep jumping forward by the sampling value...
            math::applyQuadraticFit(c2, c1, c0, x, &y);     // and run the quadratic fit, y is an out variable...
            DPoint p = (DPoint){.x = x, .y = y};
            ptad->push_back(p);                             // and store x and y in the ptad
        }
        ptaa0->push_back(*ptad);
        free(ptad);
        free(pta);
    }
    nlines = (int) ptaa0->size();
    if (quadraticCurvePoints) {
        *quadraticCurvePoints = NULL;
        *quadraticCurvePoints = new vvectorPointD(*ptaa0);
    }

    /* Remove lines with outlier curvatures.
     * Note that this is just looking for internal consistency in
     * the line curvatures. */
    double medval, medvar;
    dewarp::getMedianVariation(nacurve0, &medval, &medvar);
    vvectorPointD *ptaa1 = new vvectorPointD();
    vectorD *nacurve1 = new vectorD();

    for (i = 0; i < nlines; i++) {  /* for each line */
        val = nacurve0->at(i);
        if (abs(val - medval) > 3.0 * medvar)
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
    vectorPointD *debugPts = new vectorPointD();
    for (i = 0; i < nlines; i++) {
        vectorPointD *pta = new vectorPointD((*ptaa1)[i]);
        int npts = (int)pta->size();
        DPoint mid = pta->at(npts/2);
        namidy->push_back(mid.y);
        free(pta);
        debugPts->push_back(mid);
    }
    if (curveCenterPoints) {
        *curveCenterPoints = NULL;
        *curveCenterPoints = new vectorPointD(*debugPts);
    }
    free(debugPts);

    /**
     * Sort the lines in ptaa1 by their vertical position, going down
     */
    vectorD *namidysi = dewarp::getSortIndex(namidy, L_SORT_INCREASING);
    vectorD *namidys = dewarp::sortByIndex(namidy, namidysi);
    vectorD *nacurves = dewarp::sortByIndex(nacurve1, namidysi);
    vvectorPointD *ptaa2 = dewarp::sortByIndex(ptaa1, namidysi);
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
        vectorPointD *ptad = new vectorPointD();

        math::getQuadraticLSF(pta, &c2, &c1, &c0, NULL);
        for (i = 0; i < ny; i++) {  /* uniformly sampled in y */
            double y = i * sampling;
            double val;
            math::applyQuadraticFit(c2, c1, c0, y, &val);
            DPoint p = (DPoint){.x = y, .y = val};
            ptad->push_back(p);
        }
        ptaa5->push_back(*ptad);
        free(ptad);
        free(pta);
    }

    vvectorD *vdisparity = new vvectorD(ny, vectorD(nx, 0));
    for (i = 0; i < nx; i++) {
        for (j = 0; j < ny; j++) {
            (*vdisparity)[j][i] = (*ptaa5)[i][j].y;
        }
    }

    free(famidys);
    free(ptaa0);
    free(ptaa1);
    free(ptaa2);
    free(ptaa3);
    free(ptaa4);
    free(ptaa5);

    return [self scaleDisparity:vdisparity inputImageSize:inSize samplingInterval:sampling];
}

- (void)debugHorizontals:(Mat)display
leftQuadraticCurvePoints:(vectorPointD *)leftQuadraticCurvePoints
rightQuadraticCurvePoints:(vectorPointD *)rightQuadraticCurvePoints
           leftEndPoints:(vectorPointD *)leftEndPoints
          rightEndPoints:(vectorPointD *)rightEndPoints
               leftBound:(double)leftBound
              rightBound:(double)rightBound {
    int height = display.rows;
    Scalar red = Scalar(255, 0, 0);
    Scalar black = Scalar(0, 0, 0);
    Scalar yellow = Scalar(255, 250, 205);

    if (leftQuadraticCurvePoints) {
        for (int i = 0; i < leftQuadraticCurvePoints->size(); i++) {
            DPoint p = leftQuadraticCurvePoints->at(i);
            circle(display, Point2d(p.x, p.y), 20, red, -1, cv::LINE_AA);
        }
        free(leftQuadraticCurvePoints);
    }
    if (rightQuadraticCurvePoints) {
        for (int i = 0; i < rightQuadraticCurvePoints->size(); i++) {
            DPoint p = rightQuadraticCurvePoints->at(i);
            circle(display, Point2d(p.x, p.y), 20, red, -1, cv::LINE_AA);
        }
        free(rightQuadraticCurvePoints);
    }
    if (leftEndPoints) {
        for (int i = 0; i < leftEndPoints->size(); i++) {
            DPoint p = leftEndPoints->at(i);
            circle(display, Point2d(p.y, p.x), 12, yellow, -1, cv::LINE_AA);
        }
        free(leftEndPoints);
    }
    if (rightEndPoints) {
        for (int i = 0; i < rightEndPoints->size(); i++) {
            DPoint p = rightEndPoints->at(i);
            circle(display, Point2d(p.y, p.x), 10, yellow, -1, cv::LINE_AA);
        }
        free(rightEndPoints);
    }
    if (leftBound != 0) {
        line(display, Point2d(leftBound, 0), Point2d(leftBound, height), black, 5, cv::LINE_AA);
    }
    if (rightBound != 0) {
        line(display, Point2d(rightBound, 0), Point2d(rightBound, height), black, 5, cv::LINE_AA);
    }
}

- (void)debugVerticals:(Mat)display quadraticCurvePoints:(vvectorPointD *)quadraticCurvePoints curveCenterPoints:(vectorPointD *)curveCenterPoints {
    Scalar red = Scalar(255, 0, 0);
    Scalar yellow = Scalar(255, 250, 205);

    if (quadraticCurvePoints) {
        for (int i = 0; i < quadraticCurvePoints->size(); i++) {
            vectorPointD pts = quadraticCurvePoints->at(i);
            for (int j = 0; j < pts.size(); j++) {
                DPoint p = pts[j];
                circle(display, Point2d(p.x, p.y), 2, yellow, -1, cv::LINE_AA);
            }
        }
        free(quadraticCurvePoints);
    }
    if (curveCenterPoints) {
        for (int i = 0; i < curveCenterPoints->size(); i++) {
            DPoint mid = curveCenterPoints->at(i);
            circle(display, Point2d(mid.x, mid.y), 4, red, -1, cv::LINE_AA);
        }
        free(curveCenterPoints);
    }
}
@end

@interface DisparityModel(Extras)
@end
@implementation DisparityModel(Extras)
- (UIImage *)_apply {
    Mat inImage = [self.inputImage mat];
    Mat outImage = inImage.clone();

    DSize inSize = (DSize){
        .width = (double)inImage.cols,
        .height = (double)inImage.rows
    };
    vvectorPointD *txtLinePts = [self convertKeypoints:self.keyPoints];
    int w, h, d, i, j;
    int sampling = 80;
    int grayin = -1;
    d = inImage.channels();
    w = inSize.width;
    h = inSize.height;

    /**
     * Debugging output
     */
    BOOL debugH = false;
    vectorPointD *hLeftQuadraticCurvePoints = NULL;
    vectorPointD *hRightQuadraticCurvePoints = NULL;
    vectorPointD *hLeftEndPoints = NULL;
    vectorPointD *hRightEndPoints = NULL;
    double hLeftBound = 0;
    double hRightBound = 0;
    /** <-------------> */

    /**
     * apply the horizontal disparity map
     *     */
    vvectorD *hDisparity = [self getHorizontalDisparity:txtLinePts
                                         inputImageSize:inSize
                                       samplinginterval:sampling
                                   quadraticCurvePoints:&hLeftQuadraticCurvePoints
                                   quadraticCurvePoints:&hRightQuadraticCurvePoints
                                      leftLineEndPoints:&hLeftEndPoints
                                     rightLineEndPoints:&hRightEndPoints
                                             leftBounds:&hLeftBound
                                            rightBounds:&hRightBound];
    int jsrc;
    for (i = 0; i < h; i++) {

        for (j = 0; j < w; j++) {
            jsrc = (int)(j - hDisparity->at(i).at(j) + 0.5);

            if (grayin < 0)
                jsrc = min(max(jsrc, 0), w - 1);
            if (jsrc >= 0 && jsrc < w){
                //unsigned char *rowPtr = inImage.ptr(i);
                //outImage.at<unsigned char>(i, j) = rowPtr[jsrc];
            }
        }
    }


    free(txtLinePts);

    if (debugH)
        [self debugHorizontals:outImage
      leftQuadraticCurvePoints:hLeftQuadraticCurvePoints
     rightQuadraticCurvePoints:hRightQuadraticCurvePoints
                 leftEndPoints:hLeftEndPoints
                rightEndPoints:hRightEndPoints
                     leftBound:hLeftBound
                    rightBound:hRightBound];

    return [[UIImage alloc] initWithCVMat:outImage];
}
@end


