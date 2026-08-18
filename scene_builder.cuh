#ifndef SCENE_BUILDER_CUH
#define SCENE_BUILDER_CUH
#include <unordered_map>
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

    std::vector<aabb> bboxes;

    std::unordered_map<uint32_t, point3> box_min;
    std::unordered_map<uint32_t, uint32_t> obj_size;

    scene_builder() = default;

    uint32_t add_sphere(const point3& static_center, real radius, int mat_type, int mat_id = -1)
    {
        mat_id = get_mat_id(mat_type, mat_id);
        sphere sp(static_center, radius, mat_type, mat_id);
        spheres.push_back(sp);
        uint32_t index = spheres.size()-1;

        aabb spb;
        spb = sp.get_bounding_box();
        spb.primitive_id = new uint32_t;
        *spb.primitive_id = index << 4 | SPHERE;
        bboxes.push_back(spb);

        return index;
    }

    uint32_t add_tri(const point3& a, const point3& b, const point3& c, int mat_type, int mat_id = -1)
    {
        mat_id = get_mat_id(mat_type, mat_id);
        tri temptri{a, b, c, mat_type, mat_id};
        tris.push_back(temptri);
        uint32_t index = tris.size()-1;

        aabb trb;
        trb = temptri.get_bounding_box();
        trb.primitive_id = new uint32_t;
        *trb.primitive_id = index << 4 | TRI;
        bboxes.push_back(trb);
        return index;
    }

    uint32_t add_quad(const point3& Q, const vec3& u, const vec3& v, int mat_type, int mat_id = -1)
    {
        mat_id = get_mat_id(mat_type, mat_id);
        quad temp_quad{Q, u, v, mat_type, mat_id};
        quads.push_back(temp_quad);
        uint32_t index = quads.size()-1;

        aabb quadb;
        quadb = temp_quad.get_bounding_box();
        quadb.primitive_id = new uint32_t;
        *quadb.primitive_id = index << 4 | QUAD;
        bboxes.push_back(quadb);
        return index;
    }

    uint32_t add_sphere_inst(int primitive_id, bool abs, vec3 offset, int mat_type = -1, int mat_id = -1)
    {
        if (mat_type == -1)
        {
            mat_id = spheres[primitive_id].mat_id;
            mat_type = spheres[primitive_id].mat_type;
        }else if (mat_id == -1)
        {
            mat_id = get_mat_id(mat_type, mat_id);
        }
        if (abs)
        {
            offset = spheres[primitive_id].abs_offset(offset);
        }

        instance temp{primitive_id, offset, mat_type, mat_id};
        sphere_instances.push_back(temp);
        uint32_t index = sphere_instances.size()-1;

        aabb inst;
        inst = spheres[primitive_id].get_bounding_box() + offset;
        inst.primitive_id = new uint32_t;
        *inst.primitive_id = index << 4 | SPHERE_INST;
        bboxes.push_back(inst);
        return index;
    }

    uint32_t add_quad_inst(int primitive_id, bool abs, vec3 offset, int mat_type = -1, int mat_id = -1, bool is_box = false)
    {
        if (mat_type == -1)
        {
            mat_id = quads[primitive_id].mat_id;
            mat_type = quads[primitive_id].mat_type;
        }else if (mat_id == -1)
        {
            mat_id = get_mat_id(mat_type, mat_id);
        }

        if (abs & !is_box)
        {
            offset = quads[primitive_id].abs_offset(offset);
        }

        instance temp{primitive_id, offset, mat_type, mat_id};
        quad_instances.push_back(temp);
        uint32_t index = quad_instances.size()-1;

        aabb inst;
        inst = quads[primitive_id].get_bounding_box() + offset;
        inst.primitive_id = new uint32_t;
        *inst.primitive_id = index << 4 | QUAD_INST;
        bboxes.push_back(inst);
        return index;
    }

    uint32_t add_tri_inst(int primitive_id, bool abs, vec3 offset, int mat_type = -1, int mat_id = -1)
    {
        if (mat_type == -1)
        {
            mat_id = tris[primitive_id].mat_id;
            mat_type = tris[primitive_id].mat_type;
        }else if (mat_id == -1)
        {
            mat_id = get_mat_id(mat_type, mat_id);
        }
        if (abs)
        {
            offset = tris[primitive_id].abs_offset(offset);
        }

        instance temp{primitive_id, offset, mat_type, mat_id};
        tri_instances.push_back(temp);
        uint32_t index = tri_instances.size()-1;

        aabb inst;
        inst = tris[primitive_id].get_bounding_box() + offset;
        inst.primitive_id = new uint32_t;
        *inst.primitive_id = index << 4 | TRI_INST;
        bboxes.push_back(inst);
        return index;
    }

    uint32_t add_obj(const std::string& obj_file, const int mat_type, int mat_id = -1, real scale = 1)
    {
        uint32_t start_index = tris.size();
        std::vector<point3> pts;

        std::ifstream file(obj_file);
        std::string line;
        if (!file.is_open()) {
            std::cerr << "Failed to open file: " << obj_file << std::endl;
            exit(-1);
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

                // object.emplace_back(pts[x-1], pts[y-1], pts[z-1], mat_type, mat_id);
                add_tri(pts[x-1], pts[y-1], pts[z-1], mat_type, mat_id);
            }
        }
        uint32_t index = tris.size() - 1;
        obj_size[index] = index-start_index;
        return index;
    }

    uint32_t add_box(const point3& a, const point3& b, int mat_type, int mat_id = -1) {

        auto min = point3(std::fmin(a.x(), b.x()), std::fmin(a.y(), b.y()), std::fmin(a.z(), b.z()));
        auto max = point3(std::fmax(a.x(), b.x()), std::fmax(a.y(), b.y()), std::fmax(a.z(), b.z()));

        auto dx = vec3(max.x() - min.x(), 0, 0);
        auto dy = vec3(0, max.y() - min.y(), 0);
        auto dz = vec3(0, 0, max.z() - min.z());

        add_quad(point3(min.x(), min.y(), max.z()), dx, dy, mat_type, mat_id);
        add_quad(point3(max.x(), min.y(), max.z()), -dz, dy, mat_type, mat_id);
        add_quad(point3(max.x(), min.y(), min.z()), -dx, dy, mat_type, mat_id);
        add_quad(point3(min.x(), min.y(), min.z()), dz, dy, mat_type, mat_id);
        add_quad(point3(min.x(), max.y(), max.z()), dx, -dz, mat_type, mat_id);
        add_quad(point3(min.x(), min.y(), min.z()), dx, dz, mat_type, mat_id);

        uint32_t index = quads.size() - 1;
        box_min[index] = min;

        return index;
    }

    uint32_t add_box_instance(uint32_t id, bool abs, const point3& a, int mat_type = -1, int mat_id = -1)
    {
        vec3 offset = a;
        if (abs)
            offset = a - box_min[id];
        for (int i = 0; i < 6; i++)
        {
            add_quad_inst(id-i, abs, offset, mat_type, mat_id, true);
        }
        return quads.size() - 1;
    }

    uint32_t add_obj_instance(uint32_t id, bool abs, const point3& a, int mat_type = -1, int mat_id = -1)
    {
        vec3 offset = a;
        if (abs)
            offset = tris[id].abs_offset(a);
        for (int i = 0; i < obj_size[id]; i++)
        {
            add_tri_inst(id-i, false, offset, mat_type, mat_id);
        }
        return tris.size() - 1;
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
        primitives objects(&spheres, &quads, &tris, &sphere_instances, &quad_instances, &tri_instances);

        if constexpr (std::is_same_v<T, bvh_traverse>)
        {
            bvh temp = bvh(bboxes, objects);
            new (world) bvh_traverse(objects);
            world->leaves = temp.leaves;
            world->nodes = temp.nodes;
        }
        else
        {
            new (world) hittable_list(objects);
        }

        new (materials_arr) materials(&lambertians, &metals, &dielectrics, &diffuse_lights, &isotropics);
    }
};

#endif //SCENE_BUILDER_CUH