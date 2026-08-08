#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "util.cuh"
#include <optional>

#include "aabb.cuh"
#include "quad.cuh"
#include "shapes.cuh"
#include <vector>

template <typename primitive> struct type
{
    primitive *d_primitives = nullptr;
    uint32_t d_max_primitives = 0;

    void add(const std::vector<primitive> *primitive_arr)
    {
        if (primitive_arr)
        {
            d_max_primitives = primitive_arr->size();
            cudaMallocManaged(&d_primitives, d_max_primitives * sizeof(primitive));
            cudaMemcpy(d_primitives, primitive_arr->data(), d_max_primitives * sizeof(primitive), cudaMemcpyHostToDevice);
        }
    }
};

struct primitives
{

    type<sphere> d_spheres;
    type<quad> d_quads;
    type<tri> d_tris;
    type<instance> d_sphere_inst;
    type<instance> d_quad_inst;
    type<instance> d_tri_inst;

    primitives(const std::vector<sphere> *spheres,
        const std::vector<quad> *quads,
        const std::vector<tri> *tris,
        const std::vector<instance> *sphere_inst = nullptr,
        const std::vector<instance> *quad_inst = nullptr,
        const std::vector<instance> *tri_inst = nullptr)
    {
        if (spheres)
            d_spheres.add(spheres);
        if (quads)
            d_quads.add(quads);
        if (tris)
            d_tris.add(tris);
        if (sphere_inst)
            d_sphere_inst.add(sphere_inst);
        if (quad_inst)
            d_quad_inst.add(quad_inst);
        if (tri_inst)
            d_tri_inst.add(tri_inst);
    }
};

    template <typename T> HD inline void hit_all(T *objects, uint32_t max, const ray &r, interval &ray_t, bool &hit_anything, real &closest_so_far, hit_record &temp_rec, hit_record &rec)
    {
        for (int i = 0; i < max; ++i) {
            if (objects[i].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }
    }

    HD void inline instance_hit(primitives &objects, instance *instances, uint32_t max, const ray &r, interval &ray_t, bool &hit_anything, real &closest_so_far, hit_record &temp_rec, hit_record &rec, int prim_type)
    {
        for (int i = 0; i < max; ++i)
        {
            const instance temp = instances[i];
            ray offset_r(r.origin() - temp.offset, r.direction(), r.time());
            switch (prim_type)
            {
            case SPHERE:
                    if (objects.d_spheres.d_primitives[temp.primitive_id].hit(offset_r, interval(ray_t.min, closest_so_far), temp_rec)){
                        hit_anything = true;
                        closest_so_far = temp_rec.t;
                        rec = temp_rec;

                        rec.p += temp.offset;

                        if (temp.mat_id != -1){
                            rec.mat_type = temp.mat_type;
                            rec.mat_id = temp.mat_id;
                        }
                    }
                    break;
            case QUAD:
                {
                    if (objects.d_quads.d_primitives[temp.primitive_id].hit(offset_r, interval(ray_t.min, closest_so_far), temp_rec)){
                        hit_anything = true;
                        closest_so_far = temp_rec.t;
                        rec = temp_rec;

                        rec.p += temp.offset;

                        if (temp.mat_id != -1){
                            rec.mat_type = temp.mat_type;
                            rec.mat_id = temp.mat_id;
                        }
                    }
                    break;
                }
            case TRI:
                {
                    if (objects.d_tris.d_primitives[temp.primitive_id].hit(offset_r, interval(ray_t.min, closest_so_far), temp_rec)){
                        hit_anything = true;
                        closest_so_far = temp_rec.t;
                        rec = temp_rec;

                        rec.p += temp.offset;

                        if (temp.mat_id != -1){
                            rec.mat_type = temp.mat_type;
                            rec.mat_id = temp.mat_id;
                        }
                    }
                    break;
                }
            }
        }
    }

class hittable_list{
public:
    primitives &objects;
    hittable_list(primitives *objects) : objects(*objects) {}

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const
    {
        hit_record temp_rec;
        bool hit_anything = false;
        auto closest_so_far = ray_t.max;

        hit_all(objects.d_spheres.d_primitives, objects.d_spheres.d_max_primitives, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);
        hit_all(objects.d_quads.d_primitives, objects.d_quads.d_max_primitives, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);
        hit_all(objects.d_tris.d_primitives, objects.d_tris.d_max_primitives, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);

        instance_hit(objects, objects.d_sphere_inst.d_primitives, objects.d_sphere_inst.d_max_primitives, r, ray_t, hit_anything, closest_so_far, temp_rec, rec, SPHERE);
        instance_hit(objects, objects.d_quad_inst.d_primitives, objects.d_quad_inst.d_max_primitives, r, ray_t, hit_anything, closest_so_far, temp_rec, rec, QUAD);
        instance_hit(objects, objects.d_tri_inst.d_primitives, objects.d_tri_inst.d_max_primitives, r, ray_t, hit_anything, closest_so_far, temp_rec, rec, TRI);
        return hit_anything;
    }
};


#endif //HITTABLE_LIST_H