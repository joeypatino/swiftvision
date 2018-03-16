#include "CornerPointCostFunction.hpp"
#include "math+extras.hpp"
#include "print+extras.hpp"

CornerPointCostFunction::CornerPointCostFunction(vector<Point2d> _destinationPoints){
    destinationPoints = _destinationPoints;
    projector = new KeyPointProjector();
}

CornerPointCostFunction::~CornerPointCostFunction() {
    delete projector;
}

double CornerPointCostFunction::calc(const double* x) const {
    vector<double> parameters = getParameters();
    double params[parameters.size()];
    for (int i = 0; i < parameters.size(); i++){
        params[i] = parameters[i];
    }
    std::vector<cv::Point2d> dims;
    dims.push_back(cv::Point2d(x[0], x[1]));
    std::vector<cv::Point2d> ppts = projector->projectKeypoints(dims, params);
    cv::Mat diff = cv::Mat(destinationPoints) - cv::Mat(ppts);
    cv::Mat sqrd = diff.mul(diff);
    cv::Scalar sums = cv::sum(sqrd);
    return math::filterNanInf(sums[0]) + math::filterNanInf(sums[1]);
}
