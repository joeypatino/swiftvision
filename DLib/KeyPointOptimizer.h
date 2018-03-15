#import <UIKit/UIKit.h>
#include <iostream>

@interface KeyPointOptimizer: NSObject
- (void)optimizeParameters:(std::vector<double>)parameters withObjective:(double (^ _Nonnull )(std::vector<double> vector))objective;
@end
