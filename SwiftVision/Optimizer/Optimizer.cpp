#include "Optimizer.hpp"
#include "nlopt.h"
#include "nlopt.hpp"


typedef struct {
    double a, b;
} KeyPointCostData;

double optimizeFn(const std::vector<double> &x, std::vector<double> &grad, void *my_func_data) {
    return 0;
}

double constraintFn(unsigned n, const double *x, double *grad, void *data)
{
    KeyPointCostData *d = (KeyPointCostData *) data;
    double a = d->a, b = d->b;
    if (grad) {
        grad[0] = 3 * a * (a*x[0] + b) * (a*x[0] + b);
        grad[1] = -1.0;
    }
    return ((a*x[0] + b) * (a*x[0] + b) * (a*x[0] + b) - x[1]);
}

Optimizer::Optimizer(cv::Ptr<CostFunction> fn, vector<double> unoptimizedParameters) {
    solver = DownhillSolver::create();
    solver->setTermCriteria(cv::TermCriteria(cv::TermCriteria::MAX_ITER + cv::TermCriteria::EPS, 100000, 0.005));
    solver->setInitStep(Mat(1, int(unoptimizedParameters.size()), cv::DataType<double>::type, 1));
    solver->setFunction(fn);
    fn->setParameters(unoptimizedParameters);
    parameters = unoptimizedParameters;

    // ::nlopt::
    nlopt::algorithm alg = nlopt::algorithm::LN_COBYLA;
    nlopt::opt opt = nlopt::opt(alg, 2);

    std::vector<double> lb = { -HUGE_VAL, 0 };
    opt.set_lower_bounds(lb);
    opt.set_min_objective(optimizeFn, NULL);

    //KeyPointCostData data[] = { {0, 1}, {0, 1} };
    //opt.add_inequality_constraint(constraintFn, &data[0], 1e-8);
    //opt.add_inequality_constraint(constraintFn, &data[1], 1e-8);
    opt.set_xtol_rel(1e-4);

    std::vector<double> x = { 1.234, 5.678 };
    double minf;
    nlopt::result result = opt.optimize(x, minf);
    // ::nlopt::
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
    const clock_t begin_time = clock();
    OptimizerResult res;
    res.fun = solver->getFunction()->calc(parameters.data());
    res.x = parameters;
    res.dur = float( clock () - begin_time ) /  CLOCKS_PER_SEC;
    return res;
}
