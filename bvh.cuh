#ifndef BVH_H
#define BVH_H

#include "aabb.cuh"
#include "hittable_list.cuh"
#include <algorithm>
#include <vector>

//TODO: Manage Memory properly
//TODO: Use sorted primitives for better cache coalescing
struct bvh {
    node_aabb* nodes;
    payload* leaves;
    uint32_t size;
    primitives p_objects;

    bvh(std::vector<aabb>& objects, primitives p_obj) : p_objects(p_obj)
    {
        std::vector<aabb> bvh_arr;
        auto bbox = aabb::empty;

        std::vector<int> p_ids;

        for (auto object : objects)
        {
            bbox = aabb(bbox, object);
            p_ids.push_back(*object.primitive_id);
        }

        cudaMalloc(&bbox.primitive_id, objects.size() * sizeof(int));
        cudaMemcpy(bbox.primitive_id, p_ids.data(), objects.size() * sizeof(int), cudaMemcpyHostToDevice);
        bbox.num_primitives = p_ids.size();

        bvh_arr.push_back(bbox);

        std::vector<std::tuple<int, int, aabb, std::vector<aabb>>> queue;
        queue.emplace_back(0, -1, bbox, objects);

        while (!queue.empty())
        {
            auto current = queue.back();
            queue.pop_back();

            int parent_id = std::get<0>(current);
            int exit_id = std::get<1>(current);
            aabb current_bbox = std::get<2>(current);
            std::vector<aabb> current_objects = std::get<3>(current);

            bvh_arr[parent_id].skip = exit_id;

            real min_cost = 0;
            real cost_leaf = current_objects.size();

            auto nodes = split(current_bbox, current_objects, min_cost, cost_leaf);
            if (min_cost >= cost_leaf || std::get<1>(nodes[0]).empty() || std::get<1>(nodes[1]).empty() || min_cost > cost_leaf)
                continue;

            int right_id = bvh_arr.size();
            bvh_arr.push_back(std::get<0>(nodes[0]));
            int left_id = bvh_arr.size();
            bvh_arr.push_back(std::get<0>(nodes[1]));


            bvh_arr[parent_id].left = left_id;
            queue.emplace_back(right_id, exit_id, std::get<0>(nodes[0]), std::get<1>(nodes[0]));
            queue.emplace_back(left_id, right_id, std::get<0>(nodes[1]), std::get<1>(nodes[1]));
        }

        std::vector<node_aabb> node_vector;
        std::vector<payload> leaf_vector;

        for (auto node : bvh_arr)
        {
            node_aabb temp_node = node.get_node_aabb();
            if (temp_node.left == -1)
            {
                payload p = node.get_payload();
                int p_index = leaf_vector.size();
                temp_node.left = ~p_index;
                leaf_vector.push_back(p);
            }
            node_vector.push_back(temp_node);
        }

        cudaMalloc(&nodes, node_vector.size() * sizeof(node_aabb));
        cudaMemcpy(nodes, node_vector.data(), node_vector.size() * sizeof(node_aabb), cudaMemcpyHostToDevice);

        cudaMalloc(&leaves, leaf_vector.size() * sizeof(payload));
        cudaMemcpy(leaves, leaf_vector.data(), leaf_vector.size() * sizeof(payload), cudaMemcpyHostToDevice);

        size = bvh_arr.size();
        printf("%d\n", size);

    }

    std::vector<std::tuple<aabb, std::vector<aabb>>> split(aabb bbox, std::vector<aabb>& current, real& min_cost, real& cost_leaf)
    {
        real sa_V = bbox.surface_area();
        aabb min_bboxL, min_bboxR;
        std::vector<aabb> bbox_Larr, bbox_Rarr;
        min_cost = current.size();
        cost_leaf = current.size();

        std::sort(current.begin(), current.end(), centroid_x_compare);
        LR_split(current, sa_V, min_bboxL, min_bboxR, min_cost, bbox_Larr, bbox_Rarr);

        std::sort(current.begin(), current.end(), centroid_y_compare);
        LR_split(current, sa_V, min_bboxL, min_bboxR, min_cost, bbox_Larr, bbox_Rarr);

        std::sort(current.begin(), current.end(), centroid_z_compare);
        LR_split(current, sa_V, min_bboxL, min_bboxR, min_cost, bbox_Larr, bbox_Rarr);

        std::vector<int> p_ids;

        for (aabb obj : bbox_Larr)
        {
            p_ids.push_back(*obj.primitive_id);
        }
        int size = p_ids.size();

        cudaMalloc(&min_bboxL.primitive_id, size * sizeof(int));
        cudaMemcpy(min_bboxL.primitive_id, p_ids.data(), size * sizeof(int), cudaMemcpyHostToDevice);

        min_bboxL.num_primitives = size;

        p_ids.clear();

        for (aabb obj : bbox_Rarr)
        {
            p_ids.push_back(*obj.primitive_id);
        }

        size = p_ids.size();

        cudaMalloc(&min_bboxR.primitive_id, size * sizeof(int));
        cudaMemcpy(min_bboxR.primitive_id, p_ids.data(), size * sizeof(int), cudaMemcpyHostToDevice);
        min_bboxR.num_primitives = size;

        return {{min_bboxR, bbox_Rarr}, {min_bboxL, bbox_Larr}};
    }

    void LR_split(std::vector<aabb>& current, real sa_V, aabb& min_bboxL, aabb& min_bboxR, real& min_cost, std::vector<aabb>& bbox_Larr, std::vector<aabb>& bbox_Rarr)
    {
        for (int i = 0; i < current.size(); i++)
        {
            aabb bboxL, bboxR;
            for (size_t object_index = 0; object_index < i; object_index++)
            {
                bboxL = aabb(bboxL, current[object_index]);
            }
            for (size_t object_index = i; object_index < current.size(); object_index++)
            {
                bboxR = aabb(bboxR, current[object_index]);
            }
            real sa_L = bboxL.surface_area();
            real sa_R = bboxR.surface_area();
            real cost = 1 + (sa_L / sa_V)* i + (sa_R / sa_V)*(current.size() - i);
            if (cost < min_cost)
            {
                min_bboxL = bboxL;
                min_bboxR = bboxR;
                min_cost = cost;
                bbox_Larr.assign(current.begin(), current.begin() + i);
                bbox_Rarr.assign(current.begin() + i, current.end());
            }
        }
    }

    static inline auto centroid_x_compare = [](const aabb& a, const aabb& b)
    {
        return a.centroid_x() < b.centroid_x();
    };
    static inline auto centroid_y_compare = [](const aabb& a, const aabb& b)
    {
        return a.centroid_y() < b.centroid_y();
    };
    static inline auto centroid_z_compare = [](const aabb& a, const aabb& b)
    {
        return a.centroid_z() < b.centroid_z();
    };
};

struct bvh_traverse
{
    node_aabb* __restrict__ nodes;
    payload* __restrict__ leaves;
    primitives p_objects;

    bvh_traverse(primitives obj) : p_objects(obj){}

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const {
        uint32_t hit_list[512];
        int c = 0;

        int current_node = 0;
        while (current_node != -1)
        {
            const node_aabb hit_box = nodes[current_node];
            int skip = hit_box.skip;
            if (hit_box.hit(r, interval(ray_t.min, ray_t.max)))
            {
                int left = hit_box.left;
                if (left >= 0){
                    current_node = left;
                }else{
                    hit_list[c++] = ~left;
                    current_node = skip;
                }
            }else
            {
                current_node = skip;
            }
        }

        hit_record temp_rec;
        bool hit_anything = false;
        auto closest_so_far = ray_t.max;
        // printf("%d", c);

        for (int i = 0; i < c; i++){
            payload leaf_node = leaves[hit_list[i]];
            hit_element(leaf_node, r, ray_t, hit_anything, closest_so_far, temp_rec, rec);
        }
        return hit_anything;
    }

    HD void __forceinline__ hit_element(payload leaf_node, const ray &r, interval &ray_t, bool &hit_anything, real &closest_so_far, hit_record &temp_rec, hit_record &rec) const
    {
        for (int j = 0; j < leaf_node.num_primitives; ++j) {
            uint32_t id = leaf_node.primitive_id[j];
            switch (id & 15)
            {
            case SPHERE:
                if (p_objects.d_spheres.d_primitives[id >> 4].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                    hit_anything = true;
                    closest_so_far = temp_rec.t;
                    rec = temp_rec;
                }
                break;
            case QUAD:
                if (p_objects.d_quads.d_primitives[id >> 4].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                    hit_anything = true;
                    closest_so_far = temp_rec.t;
                    rec = temp_rec;
                }
                break;
            case TRI:
                if (p_objects.d_tris.d_primitives[id >> 4].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                    hit_anything = true;
                    closest_so_far = temp_rec.t;
                    rec = temp_rec;
                }
                break;
            case SPHERE_INST:
                {
                    const instance temp = p_objects.d_sphere_inst.d_primitives[id >> 4];
                    ray offset_r(r.origin() - temp.offset, r.direction(), r.time());
                    if (p_objects.d_spheres.d_primitives[temp.primitive_id].hit(offset_r, interval(ray_t.min, closest_so_far), temp_rec)){
                        hit_anything = true;
                        closest_so_far = temp_rec.t;
                        rec = temp_rec;

                        rec.p += temp.offset;

                        rec.mat_type = temp.mat_type;
                        rec.mat_id = temp.mat_id;
                    }
                    break;
                }
            case QUAD_INST:
                {
                    const instance temp = p_objects.d_quad_inst.d_primitives[id >> 4];
                    ray offset_r(r.origin() - temp.offset, r.direction(), r.time());
                    if (p_objects.d_quads.d_primitives[temp.primitive_id].hit(offset_r, interval(ray_t.min, closest_so_far), temp_rec)){
                        hit_anything = true;
                        closest_so_far = temp_rec.t;
                        rec = temp_rec;

                        rec.p += temp.offset;

                        rec.mat_type = temp.mat_type;
                        rec.mat_id = temp.mat_id;
                    }
                    break;
                }
            case TRI_INST:
                {
                    const instance temp = p_objects.d_tri_inst.d_primitives[id >> 4];
                    ray offset_r(r.origin() - temp.offset, r.direction(), r.time());
                    if (p_objects.d_tris.d_primitives[temp.primitive_id].hit(offset_r, interval(ray_t.min, closest_so_far), temp_rec)){
                        hit_anything = true;
                        closest_so_far = temp_rec.t;
                        rec = temp_rec;

                        rec.p += temp.offset;

                        rec.mat_type = temp.mat_type;
                        rec.mat_id = temp.mat_id;
                    }
                    break;
                }
            }
        }
    }
};

using hit_method = bvh_traverse;

#endif //BVH_H