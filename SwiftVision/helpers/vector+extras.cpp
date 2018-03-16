#include "vector+extras.hpp"

namespace vectors {
    vector<vector<double>> hstack(vector<vector<double>> mat1, vector<vector<double>> mat2) {
        // rows then cols
        int mat1R = int(mat1.size());
        int mat2R = int(mat2.size());
        int mat1C = int(mat1[0].size());
        int mat2C = int(mat2[0].size());
        assert(mat1R == mat2R);
        vector<vector<double>> output(mat1R, vector<double>(mat1C + mat2C, 0));
        for (int r = 0; r < mat1R; r++) {
            for (int m1 = 0; m1 < mat1C; m1++) {
                output[r][m1] = mat1[r][m1];
            }
            for (int m2 = 0; m2 < mat2C; m2++) {
                output[r][m2 + mat1C] = mat2[r][m2];
            }
        }
        return output;
    }

    vector<vector<double>> reshape(vector<double> p, int rows, int cols) {
        assert(rows * cols == p.size());
        vector<vector<double>> output(rows, vector<double>(cols, 0));
        int i = 0;
        for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
                output[r][c] = p[i];
                i++;
            }
        }
        return output;
    }

    vector<double> axis(int x, vector<Point2f> points) {
        vector<double> v;
        for (int i = 0; i < points.size(); i++) {
            Point2f p = points[i];
            if (x == 0) {
                v.push_back(p.x);
            } else if (x == 1) {
                v.push_back(p.y);
            }
        }
        return v;
    }

    vector<vector<double>> convert_to_vector2d(vector<Point2f> points) {
        vector<vector<double>> v(points.size(), vector<double>(2, 0));
        for (int i = 0; i < points.size(); i++) {
            cv::Point2f point = points[i];
            v[i][0] = point.x;
            v[i][1] = point.y;
        }
        return v;
    }
}
