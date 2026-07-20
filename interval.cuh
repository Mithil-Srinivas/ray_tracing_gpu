#ifndef INTERVAL_H
#define INTERVAL_H
#include "util.cuh"

struct interval {
    real min, max;

    HD interval() : min(+infinity), max(-infinity) {}

    HD interval(real min, real max): min(min), max(max) {}

    HD interval(const interval& a, const interval& b) : min(fmin(a.min, b.min)), max(fmax(a.max, b.max)) {}

    HD real size() const {
        return max - min;
    }

    HD bool contains(real x) const {
        return min <= x && x <= max;
    }

    HD bool surrounds(real x) const {
        return min < x && x < max;
    }

    HD real clamp(real x) const {
        if (x < min) return min;
        if (x > max) return max;
        return x;
    }

    HD interval expand(real delta) const
    {
        auto padding = delta / 2;
        return {min - padding, max + padding};
    }

    static const interval empty, universe;
};

inline const interval interval::empty = interval(+infinity, -infinity);
inline const interval interval::universe = interval(-infinity, +infinity);

HD inline interval operator+ (const interval& ival, real displacement) {
    return {ival.min + displacement, ival.max + displacement};
}

HD inline interval operator+ (real displacement, const interval& ival) {
    return ival + displacement;
}

#endif //INTERVAL_H