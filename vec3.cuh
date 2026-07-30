#ifndef VEC3_CUH
#define VEC3_CUH

#include <cmath>

struct alignas(16) vec3
{
    real e[3];

    HD vec3() : e{0,0,0} {}
    HD vec3(real e0, real e1, real e2) : e{e0, e1, e2} {}

    HD real x() const { return e[0]; }
    HD real y() const { return e[1]; }
    HD real z() const { return e[2]; }

    HD vec3 operator -() const { return {-e[0], -e[1], -e[2]}; }
    HD real operator[](int i) const {return e[i];}
    HD real& operator[](int i) {return e[i];}

    HD vec3& operator +=(const vec3& v) {
        e[0] += v.e[0];
        e[1] += v.e[1];
        e[2] += v.e[2];
        return *this;
    }

    HD vec3& operator *=(real t) {
        e[0] *= t;
        e[1] *= t;
        e[2] *= t;
        return *this;
    }

    HD vec3& operator /= (real t) {
        return *this *= 1 / t;
    }

    HD real length() const {
        return std::sqrt(length_squared());
    }

    HD real length_squared() const {
        return e[0]*e[0] + e[1]*e[1] + e[2]*e[2];
    }

    HD static vec3 random(rng &rand) {
        return {rand.next_real(), rand.next_real(), rand.next_real()};
    }

    HD static vec3 random(rng &rand, real min, real max) {
        return {rand.next_real(min, max), rand.next_real(min, max), rand.next_real(min, max)};
    }

    HD bool near_zero() const {
        auto s = 1e-8;
        return (std::fabs(e[0]) < s) && (std::fabs(e[1]) < s) && (std::fabs(e[2]) < s);
    }

    HD vec3 const_div(real a, real b, real c) const {
        return {e[0] / a, e[1] / b, e[2] / c};
    }

    HD vec3 const_mul(real a, real b, real c) const {
        return {e[0] * a, e[1] * b, e[2] * c};
    }
};

using point3 = vec3;

HD inline vec3 operator +(const vec3& u, const vec3& v) {
    return {u.e[0] + v.e[0], u.e[1] + v.e[1], u.e[2] + v.e[2]};
}

HD inline vec3 operator -(const vec3& u, const vec3& v) {
    return {u.e[0] - v.e[0], u.e[1] - v.e[1], u.e[2] - v.e[2]};
}


HD inline vec3 operator*(const vec3& u, const vec3 v) {
    return {u.e[0] * v.e[0], u.e[1] * v.e[1], u.e[2] * v.e[2]};
}

HD inline vec3 operator*(const vec3& u, real t) {
    return {u.e[0] * t, u.e[1] * t, u.e[2] * t};
}

HD inline vec3 operator*(real t, const vec3& v) { return v * t; }

HD inline vec3 operator/(const vec3& v, real t) { return v * (1/t); }

HD inline real dot(const vec3& u, const vec3& v) {
    return (u.e[0] * v.e[0] +
                u.e[1] * v.e[1] +
                u.e[2] * v.e[2]);
}

HD inline vec3 cross(const vec3& u, const vec3& v) {
    return {u.e[1] * v.e[2] - u.e[2] * v.e[1],
                u.e[2] * v.e[0] - u.e[0] * v.e[2],
                u.e[0] * v.e[1] - u.e[1] * v.e[0]};
}

HD inline vec3 unit_vector(const vec3& v) {
    return v / v.length();
}

HD inline vec3 random_unit_vector(rng &rand) {
    while (true) {
        auto p = vec3::random(rand, -1, 1);
        auto lensq = p.length_squared();
        if (1e-160 < lensq && lensq <= 1) {
            if constexpr (std::is_same_v<real, float>) {
                return p * rsqrtf(lensq);
            }else {
                return p * rsqrt(lensq);
            }
        }
    }
}

HD inline vec3 random_on_hemisphere(rng &rand, const vec3& normal) {
    vec3 on_unit_sphere = random_unit_vector(rand);
    if (dot(on_unit_sphere, normal) > 0.0) {
        return on_unit_sphere;
    }
    return -on_unit_sphere;
}

HD inline vec3 random_in_unit_disk(rng &rand) {
    while (true) {
        auto p = vec3(rand.next_real(-1, 1), rand.next_real(-1, 1), 0);
        if (p.length_squared() < 1)
            return p;
    }
}

HD inline vec3 reflect(const vec3& v, const vec3& n) {
    return v - 2 * dot(v,n) * n;
}

HD inline vec3 refract(const vec3& uv, const vec3& n, real etai_over_etai) {
    auto dot_v = dot(-uv, n);
    auto cos_theta = (dot_v < 1.0f) ? dot_v : 1.0f;
    vec3 r_out_perp = etai_over_etai * (uv + cos_theta * n);
    vec3 r_out_parallel = -std::sqrt(std::fabs(1 - r_out_perp.length_squared())) * n;
    return r_out_perp + r_out_parallel;
}

#endif //VEC3_CUH
