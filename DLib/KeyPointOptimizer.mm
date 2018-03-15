#import "KeyPointOptimizer.h"
#import <dlib/optimization.h>

using namespace std;
using namespace dlib;

@implementation KeyPointOptimizer
- (void)optimizeParameters:(std::vector<double>)parameters withObjective:(double (^)(std::vector<double> vector))objective {
    matrix<double> startingPoint = matrix<double>(int(parameters.size()), 1);
    for (int i = 0; i < parameters.size(); i++){
        startingPoint(i) = parameters[i];
    }
    auto be_like_target = [&](const matrix<double>& x) {
        std::vector<double> xx = std::vector<double>(x.begin(), x.end());
        return objective(xx);
    };

    double fun = find_min_bobyqa(be_like_target,
                                 startingPoint,
                                 2*startingPoint.size()+1,    // number of interpolation points
                                 uniform_matrix<double>(startingPoint.size(),1, -1e100),  // lower bound constraint
                                 uniform_matrix<double>(startingPoint.size(),1, 1e100),   // upper bound constraint
                                 1,    // initial trust region radius
                                 1e-6,  // stopping trust region radius
                                 2*startingPoint.size()+1    // max number of objective function evaluations
                                 );

    cout << "ending_point:\n" << startingPoint << endl;
    cout << "solution:\n" << fun << endl;

}
@end

