#include "functions.h"

double angleDistance(double angle_b, double angle_a) {
    double diff = angle_b - angle_a;

    while (diff > M_PI) {
        diff -= 2 * M_PI;
    }
    while (diff < -M_PI) {
        diff += 2 * M_PI;
    }
    return abs(diff);
}

double intervalOverlap(CGPoint int_a, CGPoint int_b) {
    return MIN(int_a.y, int_b.y) - MAX(int_a.x, int_b.x);
}

void describe_vector(std::vector<double> vector, char const *name ) {
    printf("\n############ %s ############\n", name);
    printf("size: {%zul}\n", vector.size());
    printf("----------------------------\n");

    std::vector<double>::iterator it = vector.begin();
    std::vector<double>::iterator const end = vector.end();

    for (; it != end; it++) {
        double p = *it;
        printf("{%f}", p);
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}

void describe_vector(std::vector<cv::Point> vector, char const *name ) {
    printf("\n############ %s ############\n", name);
    printf("size: {%zul}\n", vector.size());
    printf("----------------------------\n");

    std::vector<cv::Point>::iterator it = vector.begin();
    std::vector<cv::Point>::iterator const end = vector.end();

    for (; it != end; it++) {
        cv::Point p = *it;
        printf("{%i,%i}", p.x, p.y);
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}

void describe_vector( cv::Mat mat, char const *name ) {
    printf("\n############ cv::Mat::%s ############\n", name);
    printf("type: %i\n", mat.type());
    printf("depth: %i\n", mat.depth());
    printf("dims: %i\n", mat.dims);
    printf("channels: %i\n", mat.channels());
    printf("size: {");
    for (int i = 0; i < mat.dims; ++i) {
        printf("%i", mat.size[i]);
        if (i < mat.dims - 1){ printf(", "); }
    }
    printf(", %i", mat.cols);
    printf("}\n");
    printf("total: %zul\n", mat.total());
    printf("----------------------------\n");

    for (int i = 0; i < mat.cols; ++i) {
        double *columValues = mat.ptr<double>(i);
        printf("[");
        for (int j = 0; j < mat.rows; ++j) {
            printf("%f", columValues[j]);
            if (j < mat.rows - 1){
                printf(", ");
            }
        }
        printf("]\n");
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}

void describe_vectord(std::vector<std::vector<double>> vector, char const *name ) {
    printf("\n############ %s ############\n", name);
    printf("size: {%zul}\n", vector.size());
    printf("----------------------------\n");

    std::vector<std::vector<double>>::iterator it = vector.begin();
    std::vector<std::vector<double>>::iterator const end = vector.end();

    for (; it != end; it++) {
        std::vector<double> inner = *it;
        std::vector<double>::iterator innerIt = inner.begin();
        std::vector<double>::iterator const innerEnd = inner.end();

        for (; innerIt != innerEnd; innerIt++) {
            double val = *innerIt;
            printf("{%f}", val);
        }
    }

    printf("\n############ %s ############\n", name);
    printf("\n");
}
