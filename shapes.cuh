#ifndef SHAPES_H
#define SHAPES_H

#include <utility>

#include "util.cuh"
#include "aabb.cuh"

struct sphere {
    point3 center;
    real radius;
    int mat_type;
    int mat_id;
    aabb bbox;

    // Stationary
    HD sphere(const point3& static_center, real radius, int mat_type, int mat_id)
        : center(static_center), radius(fmax(0.0f, radius)), mat_type(mat_type), mat_id(mat_id){
        auto rvec = vec3(radius, radius, radius);
        bbox = aabb(static_center - rvec, static_center + rvec);
    }

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const  {
        vec3 oc = center - r.origin();
        auto a = r.direction().length_squared();
        auto h = dot(r.direction(), oc);
        auto c = oc.length_squared() - radius*radius;

        auto discriminant = h*h - a*c;
        if (discriminant < 0) {
            return false;
        }

        auto sqrtd = std::sqrt(discriminant);

        auto root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root)) {
                return false;
            }
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        vec3 outward_normal = (rec.p - center) / radius;
        rec.set_face_normal(r, outward_normal);
        get_sphere_uv(outward_normal, rec.u, rec.v);

        rec.mat_type = mat_type;
        rec.mat_id = mat_id;

        return true;
    }

    HD aabb bounding_box() const {return bbox;};

    HD static void get_sphere_uv(const point3& p, double& u, double& v){
        auto theta = std::acos(-p.y());
        auto phi = std::atan2(-p.z(), p.x()) + pi;

        u = phi/(2*pi);
        v = theta / pi;
    }
};

#endif //SHAPES_H