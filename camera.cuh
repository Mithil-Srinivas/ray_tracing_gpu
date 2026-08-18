#ifndef CAMERA_H
#define CAMERA_H

#include <chrono>
#include <thread>
#include <fstream>

#include "hittable_list.cuh"
#include "material.cuh"

//TODO: Needs a lot of work
//TODO: Remove unnecessary variables
class camera {
    public:
    real aspect_ratio = 16.0 / 9.0;
    int image_width = 400;
    int image_height = 400;
    int samples_per_pixel = 10;
    int max_depth = 20;
    color background = {0.0, 0.0, 0.0};

    real vfov = 90;
    point3 lookfrom = point3(0, 0, 0);
    point3 lookat = point3(0, 0, -1);
    vec3 vup = vec3(0, 1, 0);
    real defocus_angle = 0;
    real focus_dist = 10;

    int thread_count = 1;
    bool view_max_bounce = false;
    bool rendering = true;

    // std::vector<color> framebuffer;
    // std::vector<Uint32> screenbuffer;

    HD void image_write(int i, int j, vec3 *out, const hit_method *world, materials *mat_arr, rng &rand) {
        color pixel_color(0, 0, 0);
        for (int sample = 0; sample < samples_per_pixel; sample++) {
            ray r = get_ray(i, j, rand);
            pixel_color += ray_color(r, world, mat_arr, rand);
        }

        out[j * image_width + i] = pixel_color * pixel_samples_scale;
        // screenbuffer[j * image_width + i] = convert_color(pixel_color * pixel_samples_scale);
        // text[id] += write_color(pixel_samples_scale * pixel_color);
    }

    HD void initialize() {
        // image_height = int(image_width / aspect_ratio);
        // image_height = (image_height < 1) ? 1 : image_height;

        pixel_samples_scale = 1.0f / samples_per_pixel;

        center = lookfrom;

        //camera
        auto theta = degrees_to_radians(vfov);
        auto h = tan(theta / 2);
        auto viewport_height = 2 * h * focus_dist;
        auto viewport_width = viewport_height * (real(image_width)/image_height);

        w = unit_vector(lookfrom-lookat);
        u = unit_vector(cross(vup, w));
        v = cross(w, u);

        //vector edges
        auto viewport_u = viewport_width * u;
        auto viewport_v = viewport_height * -v;

        //delta v
        pixel_delta_u = viewport_u / image_width;
        pixel_delta_v = viewport_v / image_height;

        auto viewport_upper_left = center - (focus_dist * w) - viewport_u/2 - viewport_v/2;
        pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);
        // framebuffer.clear();
        // framebuffer.resize(image_height*image_width);
        // screenbuffer.clear();
        // screenbuffer.resize(image_height*image_width);

        auto defocus_radius = focus_dist * std::tan(degrees_to_radians(defocus_angle / 2));
        defocus_disk_u = defocus_radius * u;
        defocus_disk_v = defocus_radius * v;

        rendering = true;
    }

    real pixel_samples_scale;
    point3 center;
    point3 pixel00_loc;
    vec3 pixel_delta_u;
    vec3 pixel_delta_v;
    vec3 u, v, w;
    vec3 defocus_disk_u;
    vec3 defocus_disk_v;
    int t_cols, t_rows;
    std::atomic<int> tile{0};

    HD color ray_color(const ray& r, const hit_method *world, materials *mat_arr, rng& rand) {
        color throughput{1, 1, 1};
        ray current = r;

        for (int i = 0; i < max_depth; i++)
        {
            hit_record rec;
            ray scattered;

            color attenuation;

            if (!world->hit(current, interval(0.001, infinity), rec))
                return throughput * background;

            switch (rec.mat_type)
            {
            case LAMBERTIAN:
                {
                    if (!mat_arr->lambertian_mats[rec.mat_id].scatter(current, rec,attenuation ,scattered, rand)) {
                        return throughput;
                    }
                    break;
                }
            case METAL :
                {
                    if (!mat_arr->metal_mats[rec.mat_id].scatter(current, rec,attenuation ,scattered, rand)) {
                        return throughput;
                    }
                    break;
                }
            case DIELECTRIC :
                {
                    if (!mat_arr->dielectric_mats[rec.mat_id].scatter(current, rec,attenuation ,scattered, rand)) {
                        return throughput;
                    }
                    break;
                }
            case DIFFUSE_LIGHT :
                {
                    return throughput * mat_arr->diffuse_light_mats[rec.mat_id].emitted(rec.u, rec.v, rec.p);
                    break;
                }
            case ISOTROPIC :
                {
                    if (!mat_arr->isotropic_mats[rec.mat_id].scatter(current, rec,attenuation ,scattered, rand)) {
                        return throughput;
                    }
                    break;
                }
            }
            throughput = throughput * attenuation;
            current = scattered;
        }
        return throughput;
    }

    HD ray get_ray(int i, int j, rng &rand) const {
        auto offset = sample_square(rand);
        auto pixel_sample = pixel00_loc
                                + ((i + offset.x()) * pixel_delta_u)
                                + ((j + offset.y()) * pixel_delta_v);
        auto ray_origin = (defocus_angle <= 0) ? center : defocus_disk_sample(rand);
        auto ray_direction = pixel_sample - ray_origin;
        auto ray_time = rand.next_real();

        return {ray_origin, ray_direction, ray_time};
    }

    HD vec3 sample_square(rng &rand) const {
        return {rand.next_real() - real(0.5), rand.next_real() - real(0.5), 0};
    }

    HD point3 defocus_disk_sample(rng &rand) const {
        auto p = random_in_unit_disk(rand);
        return center + (p[0] * defocus_disk_u) + (p[1] * defocus_disk_v);
    }
};

#endif //CAMERA_H