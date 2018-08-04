#include "print+extras.hpp"

namespace logs {
    void describe_vector(std::vector<std::vector<double>> vector, char const *name) {
        printf("\n# %s #\n", name);
        printf("----------------------------\n");
        int numRows = int(vector.size());
        int numCols = int(vector[0].size());

        printf("[%i, %i]\n", numCols, numRows);
        printf("[");
        for (int x = 0; x < numRows; x++) {
            printf("[");
            for (int y = 0; y < numCols; y++) {
                double z = vector[x][y];
                printf("%f", z);
                if (y < numCols-1) { printf(", "); }
            }
            if (x < numRows-1) { printf("]\n"); }
            else { printf("]"); }
        }
        printf("]\n");
        printf("----------------------------\n");
        printf("\n");
    }

    void describe_vector(std::vector<double> vector, char const *name) {
        printf("\n# %s #\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");
        int numRows = int(vector.size());
        printf("[");
        for (int x = 0; x < numRows; x++) {
            double z = vector[x];
            printf("%f", z);
            if (x < numRows-1) { printf(",\n"); }
            else { printf("]\n"); }
        }
        printf("----------------------------\n");
        printf("\n");
    }

    void describe_vector(std::vector<float> vector, char const *name) {
        printf("\n# %s #\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");
        int numRows = int(vector.size());
        printf("[");
        for (int x = 0; x < numRows; x++) {
            float z = vector[x];
            printf("%f", z);
            if (x < numRows-1) { printf(",\n"); }
            else { printf("]\n"); }
        }
        printf("----------------------------\n");
        printf("\n");
    }

    void describe_vector(std::vector<std::vector<DPoint>> vector, char const *name ) {
        printf("\n# %s #\n", name);
        printf("----------------------------\n");
        int numCols = int(vector.size());
        int numRows = int(vector[0].size());
        printf("[");
        for (int x = 0; x < numCols; x++) {
            printf("[");
            for (int y = 0; y < numRows; y++) {
                DPoint z = vector[x][y];
                printf("{%f, %f}", z.x, z.y);
                if (y < numRows-1) { printf(", "); }
            }
            if (x < numCols-1) { printf("]\n"); }
            else { printf("]"); }
        }
        printf("]\n");
        printf("----------------------------\n");
        printf("\n");
    }

    void describe_vector(std::vector<DPoint> vector, char const *name ) {
        printf("\n############ DPoint %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        printf("[\n");
        for (int i = 0; i < vector.size(); i++) {
            printf("%f, %f\n", vector[i].x, vector[i].y);
        }
        printf("]\n");

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point> vector, char const *name ) {
        printf("\n############ cv::Point %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point2d> vector, char const *name ) {
        printf("\n############ cv::Point2d %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point2f> vector, char const *name ) {
        printf("\n############ cv::Point2f %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point3d> vector, char const *name) {
        printf("\n############ cv::Point3d %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector(std::vector<cv::Point3f> vector, char const *name) {
        printf("\n############ cv::Point3f %s ############\n", name);
        printf("size: {%zul}\n", vector.size());
        printf("----------------------------\n");

        std::cout << vector << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }

    void describe_vector( cv::Mat mat, char const *name ) {
        printf("\n############ cv::Mat::%s ############\n", name);
        printf("type: %i\n", mat.type());
        printf("depth: %i\n", mat.depth());
        printf("dims: %i\n", mat.dims);
        printf("channels: %i\n", mat.channels());
        printf("size: {%i, %i}\n", mat.size().height, mat.size().width);
        printf("shape: {");
        for (int i = 0; i < mat.dims; ++i) {
            printf("%i", mat.size[i]);
            if (i < mat.dims - 1){ printf(", "); }
        }
        printf(", %i", mat.cols);
        printf("}\n");
        printf("total: %zul\n", mat.total());
        printf("----------------------------\n");

        std::cout << mat << std::endl;

        printf("\n############ %s ############\n", name);
        printf("\n");
    }
}
