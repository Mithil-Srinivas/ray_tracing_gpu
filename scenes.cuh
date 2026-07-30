#ifndef SCENES_CUH
#define SCENES_CUH
#include "hittable_list.cuh"
#include "material.cuh"

void bouncing_spheres(camera *cam, int width, int height, hittable_list *world, materials *materials_arr, rng &rando)
{
    new (cam) camera();

    cam->background = color(0.7, 0.8, 1.0);
    cam->samples_per_pixel = 1;
    cam->image_width = width;
    cam->image_height = height;
    cam->lookfrom = point3(13,2,3);
    cam->lookat   = point3(0,0,-1);
    cam->vfov     = 20;
    cam->initialize();

    std::vector<lambertian> lambertians;
    std::vector<metal> metals;
    std::vector<dielectric> dielectrics;
    std::vector<sphere> spheres;

    lambertians.emplace_back(color(0.2, 0.3, 0.1));
    spheres.emplace_back(point3(0, -1000, 0), 1000.0f, LAMBERTIAN, 0);

    lambertians.emplace_back(color(0.7, 0.6, 0.5));
    spheres.emplace_back(point3(-4, 1, 0), 1.0, LAMBERTIAN, 1);

    dielectrics.emplace_back(1.5);
    spheres.emplace_back(point3(0, 1, 0), 1.0, DIELECTRIC, 0);

    metals.emplace_back(color(0.7, 0.6, 0.5), 0.0);
    spheres.emplace_back(point3(4, 1, 0), 1.0, METAL, 0);

    for (int a = -11; a < 11; a++) {
        for (int b = -11; b < 11; b++) {
            auto choose_mat = rando.next_real();
            point3 center(static_cast<real>(a) + 0.9f * rando.next_real(), 0.2f,  static_cast<real>(b) + 0.9f * rando.next_real());
            if ((center - point3(4, 0.2, 0)).length() > 0.9) {
                if (choose_mat < 0.8)
                {
                    //diffuse
                    auto albedo = color::random(rando) * color::random(rando);
                    lambertians.emplace_back(albedo);
                    spheres.emplace_back(center, 0.2f, LAMBERTIAN, lambertians.size()-1);
                }else if (choose_mat < 0.95)
                {
                    //metal
                    auto albedo = color::random(rando) * color::random(rando);
                    auto fuzz = rando.next_real(0, 1);
                    metals.emplace_back(albedo, fuzz);
                    spheres.emplace_back(center, 0.2, METAL, metals.size()-1);
                }else
                {
                    //glass
                    dielectrics.emplace_back(1.5);
                    spheres.emplace_back(center, 0.2, DIELECTRIC, dielectrics.size()-1);
                }
            }
        }
    }

    // printf("%d %d", spheres.size(), materials.size());

    primitives *objects;
    cudaMallocManaged(&objects, sizeof(primitives));

    new (objects) primitives(&spheres, nullptr, nullptr);

    new (world) hittable_list(objects);

    new (materials_arr) materials(&lambertians, &metals, &dielectrics, nullptr, nullptr);
}

void cornell(camera *cam, int width, int height, hittable_list *world,materials *materials_arr, rng &rando)
{

    new (cam) camera();

    cam->samples_per_pixel = 1;
    cam->image_width = width;
    cam->image_height = height;
    cam->background   = color(0, 0, 0);
    cam->vfov     = 40;
    cam->lookfrom = point3(278, 278, -800);
    cam->lookat   = point3(278, 278, 0);
    cam->initialize();

    std::vector<lambertian> lambertians;
    std::vector<diffuse_light> diffuse_lights;
    std::vector<quad> quads;

    lambertians.emplace_back(color(0.65, 0.05, 0.05));
    lambertians.emplace_back(color(0.73, 0.73, 0.73));
    lambertians.emplace_back(color(0.12, 0.45, 0.15));
    diffuse_lights.emplace_back(color(7, 7, 7));

    quads.emplace_back(point3(555, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),LAMBERTIAN, 2);
    quads.emplace_back(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),LAMBERTIAN, 0);
    quads.emplace_back(point3(113, 554, 127), vec3(330, 0, 0), vec3(0, 0, 305), DIFFUSE_LIGHT, 0);
    quads.emplace_back(point3(0, 555, 0), vec3(555, 0, 0), vec3(0, 0, 555),LAMBERTIAN, 1);
    quads.emplace_back(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555),LAMBERTIAN, 1);
    quads.emplace_back(point3(0, 0, 555), vec3(555, 0, 0),vec3(0, 555, 0),LAMBERTIAN, 1);

    std::vector box1 = box(point3(265,0,295), point3(165, 330, 165),LAMBERTIAN, 1);
    quads.insert(quads.begin(), box1.begin(), box1.end());

    std::vector box2 = box(point3(130,0,65), point3(165, 165, 165),LAMBERTIAN, 1);
    quads.insert(quads.begin(), box2.begin(), box2.end());

    primitives *objects;
    cudaMallocManaged(&objects, sizeof(primitives));

    new (objects) primitives(nullptr, &quads, nullptr);

    new (world) hittable_list(objects);

    new (materials_arr) materials(&lambertians, nullptr, nullptr, &diffuse_lights, nullptr);
}

#endif //SCENES_CUH
