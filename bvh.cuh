#ifndef BVH_H
#define BVH_H

#include "aabb.cuh"
#include "hittable_list.cuh"
#include <algorithm>
#include <vector>

//TODO: Manage Memory properly
struct bvh {
    aabb* bboxes;
    uint32_t size;
    primitives *p_objects;

    bvh(std::vector<aabb>& objects)
    {
        std::vector<aabb> bvh_arr;
        auto bbox = aabb::empty;

        std::vector<int> p_types;
        std::vector<int> p_ids;

        for (auto object : objects)
        {
            bbox = aabb(bbox, object);
            p_types.push_back(*object.primitive_type);
            p_ids.push_back(*object.primitive_id);
        }

        cudaMalloc(&bbox.primitive_type, objects.size() * sizeof(int));
        cudaMemcpy(bbox.primitive_type, p_types.data(), objects.size() * sizeof(int), cudaMemcpyHostToDevice);
        cudaMalloc(&bbox.primitive_id, objects.size() * sizeof(int));
        cudaMemcpy(bbox.primitive_id, p_ids.data(), objects.size() * sizeof(int), cudaMemcpyHostToDevice);
        bbox.num_primitives = p_types.size();

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

        size = bvh_arr.size();
        printf("%d\n", size);

        cudaMalloc(&bboxes, size * sizeof(aabb));
        cudaMemcpy(bboxes, bvh_arr.data(), size * sizeof(aabb), cudaMemcpyHostToDevice);
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

        std::vector<int> p_types;
        std::vector<int> p_ids;

        for (aabb obj : bbox_Larr)
        {
            p_types.push_back(*obj.primitive_type);
            p_ids.push_back(*obj.primitive_id);
        }
        int size = p_types.size();

        cudaMalloc(&min_bboxL.primitive_type, size * sizeof(int));
        cudaMemcpy(min_bboxL.primitive_type, p_types.data(), size * sizeof(int), cudaMemcpyHostToDevice);
        cudaMalloc(&min_bboxL.primitive_id, size * sizeof(int));
        cudaMemcpy(min_bboxL.primitive_id, p_ids.data(), size * sizeof(int), cudaMemcpyHostToDevice);

        min_bboxL.num_primitives = p_types.size();

        p_types.clear();
        p_ids.clear();

        for (aabb obj : bbox_Rarr)
        {
            p_types.push_back(*obj.primitive_type);
            p_ids.push_back(*obj.primitive_id);
        }

        size = p_types.size();

        cudaMalloc(&min_bboxR.primitive_type, size * sizeof(int));
        cudaMemcpy(min_bboxR.primitive_type, p_types.data(), size * sizeof(int), cudaMemcpyHostToDevice);
        cudaMalloc(&min_bboxR.primitive_id, size * sizeof(int));
        cudaMemcpy(min_bboxR.primitive_id, p_ids.data(), size * sizeof(int), cudaMemcpyHostToDevice);
        min_bboxR.num_primitives = p_types.size();

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

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const {
        hit_record temp_rec;
        bool hit_anything = false;
        auto closest_so_far = ray_t.max;

        int current_node = 0;
        while (current_node != -1)
        {
            const aabb hit_box = bboxes[current_node];
            if (hit_box.hit(r, ray_t))
            {
                if (hit_box.left != -1)
                {
                    current_node = hit_box.left;
                }else{
                    //NOTE: Only Spheres for now to test
                    for (int j = 0; j < hit_box.num_primitives; ++j) {
                        if (p_objects->d_spheres.d_primitives[hit_box.primitive_id[j]].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
                            hit_anything = true;
                            closest_so_far = temp_rec.t;
                            rec = temp_rec;
                        }
                    }
                    current_node = hit_box.skip;
                }
            }else
            {
                current_node = hit_box.skip;
            }
        }
        return hit_anything;
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

using hit_method = bvh;

#endif //BVH_H