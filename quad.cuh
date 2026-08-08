#ifndef QUAD_H
#define QUAD_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include "util.cuh"

class quad{
public:
    point3 Q;
    vec3 u, v;
    vec3 w;
    int mat_type;
    int mat_id;
    vec3 normal;
    real D;


    quad(const point3& Q, const vec3& u, const vec3& v, int mat_type, int mat_id) : Q(Q), u(u), v(v), mat_type(mat_type), mat_id(mat_id)
    {
        auto n = cross(u, v);
        normal = unit_vector(n);
        D = dot(normal, Q);
        w = n / dot(n, n);
    }

    aabb set_bounding_box() const
    {
        auto bbox_diagonal1 = aabb(Q, Q + u + v);
        auto bbox_diagonal2 = aabb(Q + u, Q + v);

        return aabb(bbox_diagonal1, bbox_diagonal2);
    }

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const
    {
        real denom = dot(normal, r.direction());

        if (std::fabs(denom) < 1e-8)
            return false;

        real t = (D - dot(normal, r.origin())) / denom;
        if (!ray_t.contains(t))
            return false;

        auto intersection = r.at(t);
        vec3 planar_hitpt_vector = intersection - Q;
        auto alpha = dot(w, cross(planar_hitpt_vector, v));
        auto beta = dot(w, cross(u, planar_hitpt_vector));

        if (!is_interior(alpha, beta, rec))
            return false;

        rec.t = t;
        rec.p = intersection;
        rec.mat_type = mat_type;
        rec.mat_id = mat_id;
        rec.set_face_normal(r, normal);

        return true;
    }

    HD bool is_interior(real a, real b, hit_record& rec) const{
        interval unit_interval = interval(0, 1);

        if (!unit_interval.contains(a) || !unit_interval.contains(b))
            return false;

        rec.u = a;
        rec.v = b;
        return true;
    }
};

inline std::vector<quad> box(const point3& a, const point3& b, int mat_type, int mat_id) {

    std::vector<quad> sides;

    auto min = point3(std::fmin(a.x(), b.x()), std::fmin(a.y(), b.y()), std::fmin(a.z(), b.z()));
    auto max = point3(std::fmax(a.x(), b.x()), std::fmax(a.y(), b.y()), std::fmax(a.z(), b.z()));

    auto dx = vec3(max.x() - min.x(), 0, 0);
    auto dy = vec3(0, max.y() - min.y(), 0);
    auto dz = vec3(0, 0, max.z() - min.z());

    sides.emplace_back(point3(min.x(), min.y(), max.z()), dx, dy, mat_type, mat_id);
    sides.emplace_back(point3(max.x(), min.y(), max.z()), -dz, dy, mat_type, mat_id);
    sides.emplace_back(point3(max.x(), min.y(), min.z()), -dx, dy, mat_type, mat_id);
    sides.emplace_back(point3(min.x(), min.y(), min.z()), dz, dy, mat_type, mat_id);
    sides.emplace_back(point3(min.x(), max.y(), max.z()), dx, -dz, mat_type, mat_id);
    sides.emplace_back(point3(min.x(), min.y(), min.z()), dx, dz, mat_type, mat_id);

    return sides;
}

class tri{
    public:
    point3 a, b, c;
    int mat_type;
    int mat_id;

    tri(const point3& a, const point3& b, const point3& c, const int mat_type, const int mat_id) : a(a), b(b), c(c), mat_type(mat_type), mat_id(mat_id) {}

    aabb bounding_box()
    {
        aabb b1 = aabb(a, b);
        aabb b2 = aabb(b, c);
        return {b1, b2};
    }

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const {
        point3 T = r.origin() - a;
        point3 e1 = b - a;
        point3 e2 = c - a;

        auto P = cross(r.direction(), e2);
        real det = dot(e1, P);
        real inv_det = 1.0f / det;
        if (std::fabs(det) < 1e-8)
            return false;

        real u = dot(T, P) * inv_det;
        auto Q = cross(T, e1);
        real v = dot(r.direction(), Q) * inv_det;

        if (!is_interior(u, v, rec))
            return false;

        real t = dot(e2, Q) * inv_det;
        if (!ray_t.contains(t))
            return false;

        auto normal = unit_vector(cross(e1, e2));
        rec.t = t;
        rec.p = r.at(t);
        rec.mat_type = mat_type;
        rec.mat_id = mat_id;
        rec.set_face_normal(r, normal);
        return true;
    }

    HD bool is_interior(real a, real b, hit_record& rec) const{
        interval unit_interval = interval(0, 1);

        if (!unit_interval.contains(a) || !unit_interval.contains(b) || !unit_interval.contains(a+b))
            return false;

        rec.u = a;
        rec.v = b;
        return true;
    }
};

std::vector<tri> obj(const std::string& obj_file, const int mat_type, const int mat_id, real scale = 1) {
    std::vector<point3> pts;
    std::vector<tri> object;

    std::ifstream file(obj_file);
    std::string line;
    if (!file.is_open()) {
        std::cerr << "Failed to open file: " << obj_file << std::endl;
        return object;
    }

    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string prefix;
        ss >> prefix;
        if (prefix == "v") {
            real x, y, z;
            ss >> x >> y >> z;
            point3 p(x, y, z);
            p = p*scale;
            pts.push_back(p);
        }else if (prefix == "f") {
            std::string v1, v2, v3;
            ss >> v1 >> v2 >> v3;

            int x = std::stoi(v1.substr(0, v1.find('/')));
            int y = std::stoi(v2.substr(0, v2.find('/')));
            int z = std::stoi(v3.substr(0, v3.find('/')));

            object.emplace_back(pts[x-1], pts[y-1], pts[z-1], mat_type, mat_id);
        }
    }
    return object;
}


struct instance
{
    int primitive_id;
    vec3 offset;
    int mat_type = -1;
    int mat_id = -1;

    instance(int primitive_id, const vec3 &offset) : primitive_id(primitive_id), offset(offset){}

    instance(int primitive_id, const vec3 &offset, int mat_type, int mat_id) : primitive_id(primitive_id), offset(offset), mat_id(mat_id), mat_type(mat_type) {}
};


// template <typename T> class rotate_y {
//     public:
//     rotate_y(T &object, double angle) : object(object) {
//         auto radians = degrees_to_radians(angle);
//         sin_theta = std::sin(radians);
//         cos_theta = std::cos(radians);
//         bbox = object->bounding_box();
//
//         point3 min(infinity, infinity, infinity);
//         point3 max(-infinity, -infinity, -infinity);
//
//         for (int i = 0; i < 2; i++) {
//             for (int j = 0; j < 2; j++) {
//                 for (int k = 0; k < 2; k++) {
//                     auto x = i*bbox.x.max + (1-i)*bbox.x.min;
//                     auto y = j*bbox.y.max + (1-j)*bbox.y.min;
//                     auto z = k*bbox.z.max + (1-k)*bbox.z.min;
//
//                     auto newx = cos_theta*x + sin_theta*z;
//                     auto newz = -sin_theta*x + cos_theta*z;
//
//                     vec3 tester(newx, y, newz);
//
//                     for (int c = 0; c < 3; c++) {
//                         min[c] = std::fmin(min[c], tester[c]);
//                         max[c] = std::fmax(max[c], tester[c]);
//                     }
//                 }
//             }
//         }
//         bbox = aabb(min, max);
//     }
//
//     HD bool hit(const ray& r, interval ray_t, hit_record& rec) const {
//         auto origin = point3(
//             (cos_theta * r.origin().x()) - (sin_theta * r.origin().z()),
//             r.origin().y(),
//             (sin_theta * r.origin().x()) + (cos_theta * r.origin().z()));
//
//         auto direction = vec3(
//             (cos_theta * r.direction().x()) - (sin_theta * r.direction().z()),
//             r.direction().y(),
//             (sin_theta * r.direction().x()) + (cos_theta * r.direction().z()));
//
//         ray rotated_r(origin, direction, r.time());
//
//         if (!object->hit(rotated_r, ray_t, rec))
//             return false;
//
//         rec.p = point3(
//             (cos_theta * rec.p.x()) + (sin_theta * rec.p.z()),
//             rec.p.y(),
//             (-sin_theta * rec.p.x()) + (cos_theta * rec.p.z()));
//
//         rec.normal = vec3(
//             (cos_theta * rec.normal.x()) + (sin_theta * rec.normal.z()),
//             rec.normal.y(),
//             (-sin_theta * rec.normal.x()) + (cos_theta * rec.normal.z()));
//
//         return true;
//     }
//
//     HD aabb bounding_box() const {return bbox;}
//
//     T object;
//     double cos_theta;
//     double sin_theta;
//     aabb bbox;
// };



#endif //QUAD_H
