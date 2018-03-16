#include "Optimizer.hpp"

CostFunction::CostFunction(vector<Point2f> _destinationPoints, vector<Point2f> _keyPointIndexes){
    destinationPoints = _destinationPoints;
    keyPointIndexes = _keyPointIndexes;
    projector = new KeyPointProjector();
}

CostFunction::~CostFunction() {
    delete projector;
}

double CostFunction::calc(const double* x) const {
    vector<Point2f> ppts = projector->projectKeypoints(keyPointIndexes, (double *)x);
    Mat diff = Mat(destinationPoints) - Mat(ppts);
    Mat sqrd = diff.mul(diff);
    Scalar sums = cv::sum(sqrd);
//    cout << "sum: " << sums[0] + sums[1] << endl;
    return sums[0] + sums[1];
}

void CostFunction::setInput(std::vector<double> input) {
    inputParams = input;
}

int CostFunction::getDims() const {
    return int(inputParams.size());
}

Optimizer::Optimizer(Ptr<CostFunction> fn, vector<double> x) {
    params = x;
    fn->setInput(params);
    solver = DownhillSolver::create();
    solver->setTermCriteria(TermCriteria(TermCriteria::MAX_ITER + TermCriteria::EPS, 5000, 0.0001));
    solver->setInitStep(Mat_<double>(1, int(x.size()), 0.5));
    solver->setFunction(fn);
}

OptimizerResult Optimizer::optimize() {
    const clock_t begin_time = clock();
    OptimizerResult res;
    res.fun = solver->minimize(params);
    res.x = params;
    res.dur = float( clock () - begin_time ) /  CLOCKS_PER_SEC;
    return res;
}

double Optimizer::optimizeOnce(vector<double> params) {
    double x[params.size()];
    for (int i = 0; i < int(params.size()); i++) {
        x[i] = params[i];
    }
    return solver->getFunction()->calc(x);
}

