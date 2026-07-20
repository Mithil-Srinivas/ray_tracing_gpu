#ifndef MATERIAL_H
#define MATERIAL_H

#include "util.cuh"
#include "texture.cuh"

//TODO: Implement Textures
//PROFILE: color& vs color

class lambertian{
public:
    color albedo;
    lambertian(const color& albedo) : albedo(albedo) {}

    HD bool scatter(const ray& r_in, const hit_record& rec, color& attenuation, ray& scattered, rng &rand) const  {
        auto scatter_direction = rec.normal + random_unit_vector(rand);
        if (scatter_direction.near_zero())
            scatter_direction = rec.normal;
        scattered = ray(rec.p, scatter_direction, r_in.time());
        attenuation = albedo;
        return true;
    }

};

class metal{
public:
    color albedo;
    real fuzz;
    metal(const color& albedo, double fuzz) : albedo(albedo), fuzz(fuzz) {}

    HD bool scatter(const ray& ray_in, const hit_record& rec, color& attenuation, ray& scattered, rng &rand) const  {
        vec3 reflected = reflect(ray_in.direction(), rec.normal);
        reflected = unit_vector(reflected) + (fuzz * random_unit_vector(rand));
        scattered = ray(rec.p, reflected, ray_in.time());
        attenuation = albedo;
        return (dot(scattered.direction(), rec.normal) > 0);
    }
};

class dielectric{
    public:
    double refraction_index;

    dielectric(double refraction_index) : refraction_index(refraction_index) {}

    HD bool scatter(const ray& ray_in, const hit_record& rec, color& attenuation, ray& scattered, rng &rand) const  {
        attenuation = color(1.0, 1.0, 1.0);
        double ri = rec.front_face ? (1.0/ refraction_index) : refraction_index;


        vec3 unit_direction = unit_vector(ray_in.direction());

        double cos_theta = std::fmin(dot(-unit_direction, rec.normal), 1.0);
        double sin_theta = std::sqrt(1.0 - cos_theta * cos_theta);

        bool cannot_refract = ri * sin_theta > 1.0;
        vec3 direction;

        if (cannot_refract || reflectance(cos_theta, ri) > rand.next_real()) {
            direction = reflect(unit_direction, rec.normal);
        }else {
            direction = refract(unit_direction, rec.normal, ri);
        }

        scattered = ray(rec.p, direction, ray_in.time());

        return true;
    }

    HD static double reflectance(double cosine, double refraction_index) {

        auto r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * std::pow((1 - cosine), 5);

    }
};

class diffuse_light {
public:
    color albedo;
    diffuse_light(const color& emit) : albedo(emit) {}

    color emitted(double u, double v, const point3& p) const {
        return albedo;
    }

};

class isotropic{
public:
    color albedo;
    isotropic(const color& albedo) : albedo(albedo) {}

    HD bool scatter(const ray& r_in, const hit_record& rec, color& attenuation, ray& scattered, rng &rand) const {
        scattered = ray(rec.p, random_unit_vector(rand), r_in.time());
        attenuation = albedo;
        return true;
    }
};


#endif //MATERIAL_H