#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "util.cuh"
#include <optional>

#include "aabb.cuh"
#include "quad.cuh"
#include "shapes.cuh"

//NOTE: Only sphere for now

struct instance;

struct primitives
{
    sphere *d_spheres = nullptr;
    uint32_t max_spheres = 0;

    quad *d_quads = nullptr;
    uint32_t max_quads = 0;

    tri *d_tris = nullptr;
    uint32_t max_tris = 0;

    instance *d_instances;
    uint32_t max_inst = 0;

    primitives(const std::vector<sphere> *spheres, const std::vector<quad> *quads, const std::vector<tri> *tris, const std::vector<instance> *instances);
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

        hit_all(objects->d_spheres, objects->max_spheres, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);

        hit_all(objects->d_quads, objects->max_quads, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);

        hit_all(objects->d_tris, objects->max_tris, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);
        
        hit_all(objects->d_instances, objects->max_inst, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);

        return hit_anything;
    }

    template <typename T> HD inline void hit_all(T *objects, uint32_t max, const ray &r, interval &ray_t, bool &hit_anything, real &closest_so_far, hit_record &temp_rec, hit_record &rec) const
    {
        for (int i = 0; i < max; ++i) {
            if (objects[i].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }
    }

    // HD aabb bounding_box() const {return bbox;}
};

struct instance
{
    primitives *objects;
    int primitive_type;
    int primitive_id;
    vec3 offset;
    aabb bbox;
    int mat_type = -1;
    int mat_id = -1;

    instance(primitives *objects, int primitive_type, int primitive_id, vec3 &offset) : objects(objects), primitive_type(primitive_type),
    primitive_id(primitive_id), offset(offset){}

    instance(primitives *objects, int primitive_type, int primitive_id, const vec3 &offset, int mat_type, int mat_id) : objects(objects), primitive_type(primitive_type),
    primitive_id(primitive_id), offset(offset), mat_id(mat_id), mat_type(mat_type) {}

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const {
        ray offset_r(r.origin() - offset, r.direction(), r.time());

        switch (primitive_type)
        {
        case SPHERE:
            {
                if (!objects->d_spheres[primitive_id].hit(offset_r, ray_t, rec))
                    return false;
                rec.p += offset;
                break;
            }
        case QUAD:
            {
                if (!objects->d_quads[primitive_id].hit(offset_r, ray_t, rec))
                    return false;

                rec.p += offset;
                break;
            }
        case TRI:
            {
                if (!objects->d_tris[primitive_id].hit(offset_r, ray_t, rec))
                    return false;

                rec.p += offset;
                break;
            }
        }

        if (mat_id != -1)
        {
            rec.mat_type = mat_type;
            rec.mat_id = mat_id;
        }

        return true;
    }
};

primitives::primitives(const std::vector<sphere> *spheres, const std::vector<quad> *quads, const std::vector<tri> *tris, const std::vector<instance> *instances){
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
    if (instances)
    {
        max_inst = instances->size();
        cudaMallocManaged(&d_instances, max_inst * sizeof(instance));
        cudaMemcpy(d_instances, instances->data(), max_inst * sizeof(instance), cudaMemcpyHostToDevice);
    }
}

#endif //HITTABLE_LIST_H