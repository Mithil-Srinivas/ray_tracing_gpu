#ifndef SCENES_CUH
#define SCENES_CUH
#include "hittable_list.cuh"
#include "material.cuh"
#include "scene_builder.cuh"

void bouncing_spheres(camera *cam, int width, int height, hit_method *world, materials *materials_arr, rng &rando)
{
    new (cam) camera();

    cam->background = color(0.7, 0.8, 1.0);
    cam->samples_per_pixel = 1;
    cam->image_width = width;
    cam->image_height = height;
    cam->lookfrom = point3(13,2,3);
    cam->lookat   = point3(0,0,0);
    cam->vfov     = 20;
    cam->initialize();

    scene_builder scene;

    scene.add_mat_lamb(color(0.2, 0.3, 0.1));
    scene.add_sphere(point3(0, -1000, 0), 1000.0f, LAMBERTIAN);

    scene.add_mat_lamb(color(0.7, 0.6, 0.5));
    scene.add_sphere(point3(-4, 1, 0), 1.0, LAMBERTIAN);

    scene.add_mat_die(1.5);
    scene.add_sphere(point3(0, 1, 0), 1.0, DIELECTRIC);

    scene.add_mat_metal(color(0.7, 0.6, 0.5), 0.0);
    scene.add_sphere(point3(4, 1, 0), 1.0, METAL);

    for (int a = -11; a < 11; a++) {
        for (int b = -11; b < 11; b++) {
            auto choose_mat = rando.next_real();
            point3 center(static_cast<real>(a) + 0.9f * rando.next_real(), 0.2f,  static_cast<real>(b) + 0.9f * rando.next_real());
            if ((center - point3(4, 0.2, 0)).length() > 0.9) {
                if (choose_mat < 0.8)
                {
                    //diffuse
                    auto albedo = color::random(rando) * color::random(rando);
                    scene.add_mat_lamb(albedo);
                    scene.add_sphere(center, 0.2f, LAMBERTIAN);
                }else if (choose_mat < 0.95)
                {
                    //metal
                    auto albedo = color::random(rando) * color::random(rando);
                    auto fuzz = rando.next_real(0, 1);
                    scene.add_mat_metal(albedo, fuzz);
                    scene.add_sphere(center, 0.2, METAL);
                }else
                {
                    //glass
                    scene.add_mat_die(1.5);
                    scene.add_sphere(center, 0.2, DIELECTRIC);
                }
            }
        }
    }

    scene.build<hit_method>(world, materials_arr);
}

void cornell(camera *cam, int width, int height, hit_method *world,materials *materials_arr, rng &rando)
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

    scene_builder scene;

    uint32_t red = scene.add_mat_lamb(color(0.65, 0.05, 0.05));
    uint32_t white = scene.add_mat_lamb(color(0.73, 0.73, 0.73));
    uint32_t green = scene.add_mat_lamb(color(0.12, 0.45, 0.15));
    scene.add_mat_diffl(color(7, 7, 7));

    scene.add_quad(point3(555, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),LAMBERTIAN, green);
    scene.add_quad(point3(0, 0, 0), vec3(0, 555, 0), vec3(0, 0, 555),LAMBERTIAN, red);
    scene.add_quad(point3(113, 554, 127), vec3(330, 0, 0), vec3(0, 0, 305), DIFFUSE_LIGHT);
    scene.add_quad(point3(0, 555, 0), vec3(555, 0, 0), vec3(0, 0, 555),LAMBERTIAN, white);
    scene.add_quad(point3(0, 0, 0), vec3(555, 0, 0), vec3(0, 0, 555),LAMBERTIAN, white);
    scene.add_quad(point3(0, 0, 555), vec3(555, 0, 0),vec3(0, 555, 0),LAMBERTIAN, white);

    scene.add_box(point3(265,0,295), point3(165, 330, 165),LAMBERTIAN, white);
    scene.add_box(point3(130,0,65), point3(165, 165, 165),LAMBERTIAN, white);

    scene.build<hit_method>(world, materials_arr);
}

void cornell_instance(
    camera *cam,
    int width,
    int height,
    hit_method *world,
    materials *materials_arr,
    rng &rando)
{
    new (cam) camera();

    cam->samples_per_pixel = 50;
    cam->image_width = width;
    cam->image_height = height;
    cam->background = color(0, 0, 0);
    cam->vfov = 40;
    cam->lookfrom = point3(278, 278, -800);
    cam->lookat = point3(278, 278, 0);
    cam->initialize();

    scene_builder scene;

    uint32_t red   = scene.add_mat_lamb(color(0.65, 0.05, 0.05));
    uint32_t white = scene.add_mat_lamb(color(0.73, 0.73, 0.73));
    uint32_t green = scene.add_mat_lamb(color(0.12, 0.45, 0.15));
    uint32_t light = scene.add_mat_diffl(color(7, 7, 7));

    // ---------------------------------------------------------
    // Cornell box walls
    // ---------------------------------------------------------

    // Right wall
    scene.add_quad(
        point3(555, 0, 0),
        vec3(0, 555, 0),
        vec3(0, 0, 555),
        LAMBERTIAN,
        green
    );

    // Left wall
    scene.add_quad(
        point3(0, 0, 0),
        vec3(0, 555, 0),
        vec3(0, 0, 555),
        LAMBERTIAN,
        red
    );

    // Light
    scene.add_quad(
        point3(113, 554, 127),
        vec3(330, 0, 0),
        vec3(0, 0, 305),
        DIFFUSE_LIGHT,
        light
    );

    // ---------------------------------------------------------
    // White surfaces
    // ---------------------------------------------------------

    // Floor -- original
    uint32_t floor = scene.add_quad(
        point3(0, 0, 0),
        vec3(555, 0, 0),
        vec3(0, 0, 555),
        LAMBERTIAN,
        white
    );

    // Ceiling -- instance of floor
    scene.add_quad_inst(
        floor,
        true,
        vec3(0, 555, 0)
    );

    // Back wall
    scene.add_quad(
        point3(0, 0, 555),
        vec3(555, 0, 0),
        vec3(0, 555, 0),
        LAMBERTIAN,
        white
    );

    // ---------------------------------------------------------
    // Boxes
    // ---------------------------------------------------------

    uint32_t box = scene.add_box(
    point3(265, 0, 295),
    point3(165, 330, 165),
    LAMBERTIAN,
    white
    );

    scene.add_box_instance(
        box,
        true,
        point3(130, 0, 65)
    );

    scene.build<hit_method>(world, materials_arr);
}

void simple_light(camera *cam, int width, int height,
                  hit_method *world,
                  materials *materials_arr,
                  rng &rando)
{
    new (cam) camera();

    cam->background = color(0, 0, 0);
    cam->samples_per_pixel = 5;
    cam->image_width  = width;
    cam->image_height = height;

    cam->lookfrom = point3(26, 3, 6);
    cam->lookat   = point3(0, 2, 0);
    cam->vfov     = 20;

    cam->initialize();

    scene_builder scene;

    scene.add_mat_lamb(color(0.5, 0.5, 0.5));

    // Ground
    scene.add_sphere(
        point3(0, -1000, 0),
        1000,
        LAMBERTIAN,
        0
    );

    // Center sphere
    scene.add_sphere(
        point3(0, 2, 0),
        2,
        LAMBERTIAN,
        0
    );


    // Light material
    scene.add_mat_diffl(color(4, 4, 4));

    // Light sphere
    scene.add_sphere(
        point3(0, 7, 0),
        2,
        DIFFUSE_LIGHT,
        0
    );

    // Light quad
    scene.add_quad(
        point3(3, 1, -2),
        vec3(2, 0, 0),
        vec3(0, 2, 0),
        DIFFUSE_LIGHT,
        0
    );

    scene.build<hit_method>(world, materials_arr);
}

void tea(camera *cam, int width, int height, hit_method *world, materials *materials_arr, rng &rando)
{
    new (cam) camera();
    cam->background = color(0.7, 0.8, 1.0);
    cam->samples_per_pixel = 1;
    cam->image_width  = width;
    cam->image_height = height;

    cam->lookfrom = point3(10, 10, 10);
    cam->lookat   = point3(0, 0, 0);
    cam->vfov     = 40;

    cam->initialize();

    scene_builder scene;

    scene.add_mat_lamb(color(0.4, 0.2, 0.1));

    std::cout << scene.add_obj("teapot.obj", LAMBERTIAN) << std::endl;

    scene.build<hit_method>(world, materials_arr);
}

void tea_instance(
    camera *cam,
    int width,
    int height,
    hit_method *world,
    materials *materials_arr,
    rng &rando)
{
    new (cam) camera();

    cam->background = color(0.7, 0.8, 1.0);
    cam->samples_per_pixel = 1;
    cam->image_width = width;
    cam->image_height = height;

    cam->lookfrom = point3(15, 10, 15);
    cam->lookat   = point3(0, 2, 0);
    cam->vfov     = 40;

    cam->initialize();

    scene_builder scene;

    uint32_t brown = scene.add_mat_lamb(
        color(0.4, 0.2, 0.1)
    );

    // Original teapot
    uint32_t tea = scene.add_obj(
        "teapot.obj",
        LAMBERTIAN
    );

    // Instance 1
    scene.add_obj_instance(
        tea,
        true,
        point3(-4, 0, 0)
    );

    // Instance 2
    scene.add_obj_instance(
        tea,
        true,
        point3(4, 0, 0)
    );

    scene.build<hit_method>(world, materials_arr);
}

void bouncing_instances(camera *cam, int width, int height, hit_method *world, materials *materials_arr, rng &rando)
{
    new (cam) camera();

    cam->background = color(0.7, 0.8, 1.0);
    cam->samples_per_pixel = 1;
    cam->image_width = width;
    cam->image_height = height;
    cam->lookfrom = point3(13,2,3);
    cam->lookat   = point3(0,0,0);
    cam->vfov     = 20;
    cam->initialize();

    scene_builder scene;

    scene.add_mat_lamb(color(0.2, 0.3, 0.1));
    scene.add_sphere(point3(0, -1000, 0), 1000.0f, LAMBERTIAN);

    scene.add_mat_lamb(color(0.7, 0.6, 0.5));
    uint32_t med = scene.add_sphere(point3(-4, 1, 0), 1.0, LAMBERTIAN);

    scene.add_mat_die(1.5);
    scene.add_sphere_inst(med, true, point3(0, 1, 0), DIELECTRIC);

    scene.add_mat_metal(color(0.7, 0.6, 0.5), 0.0);
    scene.add_sphere_inst(med, true, point3(4, 1, 0), METAL);

    uint32_t small = scene.add_sphere(point3(-10, 0, 0), 0.2f, LAMBERTIAN, 0);

    for (int a = -11; a < 11; a++) {
        for (int b = -11; b < 11; b++) {
            auto choose_mat = rando.next_real();
            point3 center(static_cast<real>(a) + 0.9f * rando.next_real(), 0.2f,  static_cast<real>(b) + 0.9f * rando.next_real());
            if ((center - point3(4, 0.2, 0)).length() > 0.9) {
                if (choose_mat < 0.8)
                {
                    //diffuse
                    auto albedo = color::random(rando) * color::random(rando);
                    scene.add_mat_lamb(albedo);
                    scene.add_sphere_inst(small, true, center, LAMBERTIAN);
                }else if (choose_mat < 0.95)
                {
                    //metal
                    auto albedo = color::random(rando) * color::random(rando);
                    auto fuzz = rando.next_real(0, 1);
                    scene.add_mat_metal(albedo, fuzz);
                    scene.add_sphere_inst(small, true, center, METAL);
                }else
                {
                    //glass
                    scene.add_mat_die(1.5);
                    scene.add_sphere_inst(small, true, center, DIELECTRIC);
                }
            }
        }
    }

    scene.build<hit_method>(world, materials_arr);
}


void bvh_test(camera *cam, int width, int height, hit_method *world, materials *materials_arr, rng &rando)
{
    new (cam) camera();

    cam->background = color(0.7, 0.8, 1.0);
    cam->samples_per_pixel = 1;
    cam->image_width = width;
    cam->image_height = height;
    cam->lookfrom = point3(13,2,3);
    cam->lookat   = point3(0,0,0);
    cam->vfov     = 20;
    cam->initialize();

    scene_builder scene;

    scene.add_mat_lamb(color(0.2, 0.3, 0.1));
    scene.add_sphere(point3(0, -1000, 0), 1000.0f, LAMBERTIAN);

    scene.add_mat_lamb(color(0.7, 0.6, 0.5));
    scene.add_sphere(point3(-4, 1, 0), 1.0, LAMBERTIAN);

    scene.add_mat_die(1.5);
    scene.add_sphere(point3(0, 1, 0), 1.0, DIELECTRIC);

    scene.add_mat_metal(color(0.7, 0.6, 0.5), 0.0);
    scene.add_sphere(point3(4, 1, 0), 1.0, METAL);

    scene.build<hit_method>(world, materials_arr);
}
#endif //SCENES_CUH
