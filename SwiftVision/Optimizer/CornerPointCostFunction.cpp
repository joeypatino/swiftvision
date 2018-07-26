#include "CornerPointCostFunction.hpp"
#include "math+extras.hpp"
#include "print+extras.hpp"

CornerPointCostFunction::CornerPointCostFunction(vector<Point2d> _destinationPoints, vector<double> _keyPoints){
    destinationPoints = _destinationPoints;
    keyPoints = _keyPoints;
    projector = new KeyPointProjector();
}

CornerPointCostFunction::~CornerPointCostFunction() {
    delete projector;
}

double CornerPointCostFunction::calc(const double* x) const {
    std::vector<cv::Point2d> dims;
    dims.push_back(cv::Point2d(x[0], x[1]));
    std::vector<cv::Point2d> ppts = projector->projectXY(dims, (double *)keyPoints.data());
    cv::Mat diff = cv::Mat(destinationPoints) - cv::Mat(ppts);
    cv::Mat sqrd = diff.mul(diff);
    cv::Scalar sums = cv::sum(sqrd);
    return math::filterNanInf(sums[0]) + math::filterNanInf(sums[1]);
}
