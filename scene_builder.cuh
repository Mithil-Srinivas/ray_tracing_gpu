#ifndef SCENE_BUILDER_CUH
#define SCENE_BUILDER_CUH
#include <vector>

#include "aabb.cuh"
#include "bvh.cuh"
#include "hittable_list.cuh"
#include "material.cuh"
#include "quad.cuh"
#include "shapes.cuh"

class scene_builder
{
    public:
    std::vector<sphere> spheres;
    std::vector<tri> tris;
    std::vector<quad> quads;

    std::vector<instance> sphere_instances;
    std::vector<instance> quad_instances;
    std::vector<instance> tri_instances;

    std::vector<lambertian> lambertians;
    std::vector<metal> metals;
    std::vector<dielectric> dielectrics;
    std::vector<diffuse_light> diffuse_lights;
    std::vector<isotropic> isotropics;

    std::vector<aabb> sphere_bboxes;

    scene_builder() = default;

    uint32_t add_sphere(const point3& static_center, real radius, int mat_type, int mat_id = -1)
    {
        mat_id = get_mat_id(mat_type, mat_id);
        sphere sp(static_center, radius, mat_type, mat_id);
        spheres.push_back(sp);
        uint32_t index = spheres.size()-1;

        aabb spb;
        spb = sp.bounding_box();
        spb.primitive_type = new int(SPHERE);
        spb.primitive_id = new int;
        *spb.primitive_id = spheres.size()-1;
        sphere_bboxes.push_back(spb);

        return spheres.size()-1;
    }

    uint32_t add_mat_lamb(const color& albedo)
    {
        lambertians.emplace_back(albedo);
        return lambertians.size()-1;
    }

    uint32_t add_mat_metal(const color& albedo, real fuzz)
    {
        metals.emplace_back(albedo, fuzz);
        return metals.size()-1;
    }

    uint32_t add_mat_die(real refraction_index)
    {
        dielectrics.emplace_back(refraction_index);
        return dielectrics.size()-1;
    }

    uint32_t add_mat_diffl(const color& emit)
    {
        diffuse_lights.emplace_back(emit);
        return diffuse_lights.size()-1;
    }

    uint32_t add_mat_iso(const color& albedo)
    {
        isotropics.emplace_back(albedo);
        return isotropics.size()-1;
    }

    uint32_t get_mat_id(int mat_type, int mat_id = -1)
    {
        if (mat_id == -1)
        {
            switch (mat_type)
            {
                case LAMBERTIAN:
                    {
                        mat_id = lambertians.size()-1;
                        break;
                    }
                case METAL:
                    {
                        mat_id = metals.size()-1;
                        break;
                    }
                case DIELECTRIC:
                    {
                        mat_id = dielectrics.size()-1;
                        break;
                    }
                case DIFFUSE_LIGHT:
                    {
                        mat_id = diffuse_lights.size()-1;
                        break;
                    }
            case ISOTROPIC:
                    {
                        mat_id = isotropics.size()-1;
                        break;
                    }
            }
        }
        return mat_id;
    }

    template <typename T>
    void build(T *world, materials *materials_arr)
    {
        primitives *objects;
        cudaMallocManaged(&objects, sizeof(primitives));

        new (objects) primitives(&spheres, &quads, &tris, &sphere_instances, &quad_instances, &tri_instances);

        if constexpr (std::is_same_v<T, bvh>)
        {
            new (world) bvh(sphere_bboxes);
            world->p_objects = objects;
        }
        else
        {
            new (world) hittable_list(objects);
        }

        new (materials_arr) materials(&lambertians, &metals, &dielectrics, &diffuse_lights, &isotropics);
    }
};

#endif //SCENE_BUILDER_CUH