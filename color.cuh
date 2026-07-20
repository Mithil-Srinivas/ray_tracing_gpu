#ifndef COLOR_H
#define COLOR_H

#include <format>
#include <cstdint>
#include "util.cuh"

// #include "interval.h"
#include <string>

#include "interval.cuh"
#include "vec3.cuh"

using color = vec3;

inline real linear_to_gamma(real linear_component) {
    if (linear_component > 0) {
        return std::sqrt(linear_component);
    }
    return 0;
}

inline std::string write_color(const color& pixel_color) {
    auto r = pixel_color.x();
    auto g = pixel_color.y();
    auto b = pixel_color.z();

    r = linear_to_gamma(r);
    g = linear_to_gamma(g);
    b = linear_to_gamma(b);

    static const interval intensity(0.000, 0.999);
    int rbyte = int(256 * intensity.clamp(r));
    int gbyte = int(256 * intensity.clamp(g));
    int bbyte = int(256 * intensity.clamp(b));

    return std::to_string(rbyte) + " " + std::to_string(gbyte) + " " + std::to_string(bbyte) + "\n";

    // out << rbyte << ' ' << gbyte << ' ' << bbyte << '\n';
}

#endif //COLOR_H