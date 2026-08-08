#ifndef UTIL_CUH
#define UTIL_CUH

#define HD __device__ __host__

using real = float;

constexpr  real infinity = std::numeric_limits<real>::infinity();
constexpr  real pi = 3.1415926535897932385;

HD inline real degrees_to_radians(real angle) {
    return angle * pi / 180.0;
}

struct xorshift32 {
    uint32_t state;

    HD explicit xorshift32(uint32_t seed)
    {
        pcg_hash(seed > 1 ? seed : 1);
    }

    HD void pcg_hash(uint32_t input)
    {
        uint32_t x = input * 747796405u + 2891336453u;
        uint32_t word = ((x >> ((x >> 28u) + 4u)) ^ x) * 277803737u;

        state = (word >> 22u) ^ word;
    }

    HD uint32_t nextu32()
    {
        uint32_t x = state;

        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;

        state = x;
        return x;
    }

    HD float next_float()
    {
        return nextu32() * (1.0f / 4294967296.0f);
    }

    HD double next_double()
    {
        return nextu32() * (1.0 / 4294967296.0);
    }

    HD real next_real()
    {
        if constexpr (std::is_same_v<real, float>)
        {
            return next_float();
        }else
        {
            return next_double();
        }
    }

    HD real next_real(real min, real max)
    {
        return min + (max - min) * next_real();
    }
};

using rng = xorshift32;



#include "vec3.cuh"
#include "ray.cuh"
#include "interval.cuh"
#include "color.cuh"
#include <vector>

class hit_record {
public:
    point3 p;
    vec3 normal;
    int mat_type;
    int mat_id;
    real t;
    double u;
    double v;
    bool front_face;

    HD void set_face_normal(const ray& r, const vec3& outward_normal) {
        front_face = dot(r.direction(), outward_normal) < 0;
        normal = front_face ? outward_normal : -outward_normal;
    }
};

#define LAMBERTIAN 0
#define METAL 1
#define DIELECTRIC 2
#define DIFFUSE_LIGHT 3
#define ISOTROPIC 4

#define SPHERE 0
#define QUAD 1
#define TRI 2

#endif //UTIL_CUH
