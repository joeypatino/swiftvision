#import "KeyPointOptimizer.h"
#import <dlib/optimization.h>

using namespace std;
using namespace dlib;

@implementation KeyPointOptimizer
- (instancetype)initWithBaseParameters:(NSArray <NSNumber *> *)params
                     destinationPoints:(NSArray <NSValue *> *)dstPoints {
    self = [super init];
    _baseParameters = params;
    _destinationPoints = dstPoints;
    return self;
}

- (void)optimizeWithObjective:(double (^)(std::vector<double> vector))objective {
    matrix<double> startingPoint = matrix<double>(int(self.baseParameters.count), 1);
    for (int i = 0; i < self.baseParameters.count; i++){
        startingPoint(i) = self.baseParameters[i].doubleValue;
    }
    auto be_like_target = [&](const matrix<double>& x) {
        std::vector<double> xx = std::vector<double>(x.begin(), x.end());
        return objective(xx);
    };

    find_min_bobyqa(be_like_target,
                    startingPoint,
                    2*startingPoint.size()+1,    // number of interpolation points
                    uniform_matrix<double>(startingPoint.size(),1, -1e100),  // lower bound constraint
                    uniform_matrix<double>(startingPoint.size(),1, 1e100),   // upper bound constraint
                    10,    // initial trust region radius
                    1e-6,  // stopping trust region radius
                    100    // max number of objective function evaluations
                    );
        cout << "be_like_target solution:\n" << startingPoint << endl;
}
@end

