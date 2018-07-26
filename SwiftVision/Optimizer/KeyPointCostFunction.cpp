#include "KeyPointCostFunction.hpp"
#include "math+extras.hpp"

KeyPointCostFunction::KeyPointCostFunction(vector<Point2d> _destinationPoints, vector<Point2d> _keyPointIndexes){
    destinationPoints = _destinationPoints;
    keyPointIndexes = _keyPointIndexes;
    projector = new KeyPointProjector();
}

KeyPointCostFunction::~KeyPointCostFunction() {
    delete projector;
}

double KeyPointCostFunction::calc(const double* x) const {
    std::vector<cv::Point2d> ppts = projector->projectKeypoints(keyPointIndexes, (double *)x);
    cv::Mat diff = cv::Mat(destinationPoints) - cv::Mat(ppts);
    cv::Mat sqrd = diff.mul(diff);
    cv::Scalar sums = cv::sum(sqrd);
    return sums[0] + sums[1];
    //return math::filterNanInf(sums[0]) + math::filterNanInf(sums[1]);
}
