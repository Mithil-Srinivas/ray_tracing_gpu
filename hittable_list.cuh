#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "util.cuh"
#include <optional>

#include "aabb.cuh"
#include "shapes.cuh"

//NOTE: Only sphere for now

using std::make_shared;
using std::shared_ptr;

class hittable_list{
public:
    sphere objects[1];
    // aabb bbox;
    // hittable_list() {};
    hittable_list(sphere &object) : objects{object} {}

    std::optional<double> cam_vfov;
    std::optional<point3> cam_lookat;
    std::optional<point3> cam_lookfrom;
    std::optional<color> background;

    // void clear() { objects.clear(); }

    // sphere add(sphere &object) {
    //     bbox = aabb(bbox, object.bounding_box());
    //     return object;
    // }

    HD bool hit(const ray& r, interval ray_t, hit_record& rec) const
    {
        hit_record temp_rec;
        bool hit_anything = false;
        auto closest_so_far = ray_t.max;

        // for (const auto& object: objects) {
        //     if (object.hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
        //         hit_anything = true;
        //         closest_so_far = temp_rec.t;
        //         rec = temp_rec;
        //     }
        // }
        // printf("%zu\n", sizeof(lambertian));

        if (objects[0].hit(r, interval(ray_t.min, closest_so_far), temp_rec)) {
            hit_anything = true;
            closest_so_far = temp_rec.t;
            rec = temp_rec;
        }
        return hit_anything;
    }

    // HD aabb bounding_box() const {return bbox;}
};

#endif //HITTABLE_LIST_H