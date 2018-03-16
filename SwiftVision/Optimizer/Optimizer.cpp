#include "Optimizer.hpp"

Optimizer::Optimizer(cv::Ptr<CostFunction> fn, vector<double> unoptimizedParameters) {
    solver = DownhillSolver::create();
    solver->setTermCriteria(cv::TermCriteria(cv::TermCriteria::MAX_ITER + cv::TermCriteria::EPS, 5000, 0.0001));
    solver->setInitStep(Mat(1, int(unoptimizedParameters.size()), cv::DataType<double>::type, 0.5));
    solver->setFunction(fn);
    fn->setParameters(unoptimizedParameters);
    parameters = unoptimizedParameters;
}

OptimizerResult Optimizer::optimize() {
    const clock_t begin_time = clock();
    OptimizerResult res;
    res.fun = solver->minimize(parameters);
    res.x = parameters;
    res.dur = float( clock () - begin_time ) /  CLOCKS_PER_SEC;
    return res;
}

OptimizerResult Optimizer::initialOptimization() {
    double x[parameters.size()];
    for (int i = 0; i < int(parameters.size()); i++) {
        x[i] = parameters[i];
    }

    const clock_t begin_time = clock();
    OptimizerResult res;
    res.fun = solver->getFunction()->calc(x);
    res.x = parameters;
    res.dur = float( clock () - begin_time ) /  CLOCKS_PER_SEC;
    return res;
}
