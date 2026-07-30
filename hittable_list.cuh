#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "util.cuh"
#include <optional>

#include "aabb.cuh"
#include "quad.cuh"
#include "shapes.cuh"

//NOTE: Only sphere for now


struct primitives
{
    sphere *d_spheres = nullptr;
    uint32_t max_spheres = 0;

    quad *d_quads = nullptr;
    uint32_t max_quads = 0;

    tri *d_tris = nullptr;
    uint32_t max_tris = 0;

    primitives(const std::vector<sphere> *spheres, const std::vector<quad> *quads, const std::vector<tri> *tris)
    {
        if (spheres)
        {
            max_spheres = spheres->size();
            cudaMallocManaged(&d_spheres, max_spheres * sizeof(sphere));
            cudaMemcpy(d_spheres, spheres->data(), max_spheres * sizeof(sphere), cudaMemcpyHostToDevice);
        }
        if (quads)
        {
            max_quads = quads->size();
            cudaMallocManaged(&d_quads, max_quads * sizeof(quad));
            cudaMemcpy(d_quads, quads->data(), max_quads * sizeof(quad), cudaMemcpyHostToDevice);
        }
        if (tris)
        {
            max_tris = tris->size();
            cudaMallocManaged(&d_tris, max_tris * sizeof(tri));
            cudaMemcpy(d_tris, tris->data(), max_tris * sizeof(tri), cudaMemcpyHostToDevice);
        }
    }
};

class hittable_list{
public:
    primitives *objects;
    // aabb bbox;
    // hittable_list() {};
    hittable_list(primitives *objects) : objects(objects) {}

    std::optional<double> cam_vfov;
    std::optional<point3> cam_lookat;
    std::optional<point3> cam_lookfrom;
    std::optional<color> background;

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const
    {
        hit_record temp_rec;
        bool hit_anything = false;
        auto closest_so_far = ray_t.max;

        for (int i = 0; i < objects->max_spheres; ++i) {
            if (objects->d_spheres[i].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }

        for (int i = 0; i < objects->max_quads; ++i) {
            if (objects->d_quads[i].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }

        for (int i = 0; i < objects->max_tris; ++i) {
            if (objects->d_tris[i].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }

        return hit_anything;
    }

    // HD aabb bounding_box() const {return bbox;}
};

#endif //HITTABLE_LIST_H