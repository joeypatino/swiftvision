#include "CostFunction.hpp"

double CostFunction::calc(const double* x) const {
    cout << "not implemented!" << endl;
    return 0;
}

void CostFunction::setParameters(std::vector<double> input) {
    inputParams = input;
}

std::vector<double> CostFunction::getParameters() const {
    return inputParams;
}

int CostFunction::getDims() const {
    return int(inputParams.size());
}
