#ifndef RAY_CUH
#define RAY_CUH

#include "util.cuh"

struct ray {
    point3 orig;
    vec3 dir;
    real tm;
    HD ray(){}
    HD ray(const point3& origin, const vec3& dir, real time) : orig(origin), dir(dir), tm(time) {}
    HD ray(const point3& origin, const vec3& dir) : ray(origin, dir, 0) {}

    HD const point3& origin() const { return orig; }
    HD const vec3& direction() const { return dir; }

    HD real time() const { return tm; }

    HD point3 at(real t) const {
        // return orig;
        return orig + t * dir;
    }
};

#endif //RAY_CUH