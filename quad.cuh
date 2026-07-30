#ifndef QUAD_H
#define QUAD_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <array>
#include "hittable_list.cuh"


class quad{
public:
    point3 Q;
    vec3 u, v;
    vec3 w;
    int mat_type;
    int mat_id;
    aabb bbox;
    vec3 normal;
    double D;


    quad(const point3& Q, const vec3& u, const vec3& v, int mat_type, int mat_id) : Q(Q), u(u), v(v), mat_type(mat_type), mat_id(mat_id)
    {
        auto n = cross(u, v);
        normal = unit_vector(n);
        D = dot(normal, Q);
        w = n / dot(n, n);

        set_bounding_box();
    }

    HD void set_bounding_box()
    {
        auto bbox_diagonal1 = aabb(Q, Q + u + v);
        auto bbox_diagonal2 = aabb(Q + u, Q + v);
        bbox = aabb(bbox_diagonal1, bbox_diagonal2);
    }

    HD aabb bounding_box() const { return bbox; };

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const
    {
        auto denom = dot(normal, r.direction());

        if (std::fabs(denom) < 1e-8)
            return false;

        auto t = (D - dot(normal, r.origin())) / denom;
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

    HD bool is_interior(double a, double b, hit_record& rec) const{
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
    aabb bbox;

    tri(const point3& a, const point3& b, const point3& c, const int mat_type, const int mat_id) : a(a), b(b), c(c), mat_type(mat_type), mat_id(mat_id) {
        aabb b1 = aabb(a, b);
        aabb b2 = aabb(b, c);
        bbox = aabb(b1, b2);
    }

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const {
        point3 T = r.origin() - a;
        point3 e1 = b - a;
        point3 e2 = c - a;

        auto P = cross(r.direction(), e2);
        double det = dot(e1, P);
        double inv_det = 1.0 / det;
        if (std::fabs(det) < 1e-8)
            return false;

        double u = dot(T, P) * inv_det;
        auto Q = cross(T, e1);
        double v = dot(r.direction(), Q) * inv_det;

        if (!is_interior(u, v, rec))
            return false;

        double t = dot(e2, Q) * inv_det;
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

    aabb bounding_box() const { return bbox; };

    HD bool is_interior(double a, double b, hit_record& rec) const{
        interval unit_interval = interval(0, 1);

        if (!unit_interval.contains(a) || !unit_interval.contains(b) || !unit_interval.contains(a+b))
            return false;

        rec.u = a;
        rec.v = b;
        return true;
    }
};

// inline shared_ptr<hittable> obj(std::string obj_file, const shared_ptr<material>& mat, double scale = 1) {
//     std::vector<point3> pts;
//     auto object = make_shared<hittable_list>();
//
//     std::ifstream file(obj_file);
//     std::string line;
//     if (!file.is_open()) {
//         std::cerr << "Failed to open file: " << obj_file << std::endl;
//         return nullptr;
//     }
//
//     while (std::getline(file, line)) {
//         std::stringstream ss(line);
//         std::string prefix;
//         ss >> prefix;
//         if (prefix == "v") {
//             double x, y, z;
//             ss >> x >> y >> z;
//             point3 p(x, y, z);
//             p = p*scale;
//             pts.push_back(p);
//         }else if (prefix == "f") {
//             std::string v1, v2, v3;
//             ss >> v1 >> v2 >> v3;
//
//             int x = std::stoi(v1.substr(0, v1.find('/')));
//             int y = std::stoi(v2.substr(0, v2.find('/')));
//             int z = std::stoi(v3.substr(0, v3.find('/')));
//
//             object->add(make_shared<tri>(pts[x-1], pts[y-1], pts[z-1], mat));
//         }
//     }
//     return make_shared<bvh_node>(*object);
// }

#endif //QUAD_H
