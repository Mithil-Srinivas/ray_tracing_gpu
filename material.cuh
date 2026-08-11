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
    metal(const color& albedo, real fuzz) : albedo(albedo), fuzz(fuzz) {}

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
    real refraction_index;

    dielectric(real refraction_index) : refraction_index(refraction_index) {}

    HD bool scatter(const ray& ray_in, const hit_record& rec, color& attenuation, ray& scattered, rng &rand) const  {
        attenuation = color(1.0, 1.0, 1.0);
        real ri = rec.front_face ? (1.0f/ refraction_index) : refraction_index;


        vec3 unit_direction = unit_vector(ray_in.direction());

        real dot_val = dot(-unit_direction, rec.normal);
        real cos_theta = (dot_val < 1.0f) ? dot_val : 1.0f;
        real sin_theta = 0;
        sin_theta = sqrt(1.0f - cos_theta * cos_theta);

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

    HD static real reflectance(real cosine, real refraction_index) {

        auto r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * pow(1.0f - cosine, 5.0f);
    }
};

class diffuse_light {
public:
    color albedo;
    diffuse_light(const color& emit) : albedo(emit) {}

    HD color emitted(double u, double v, const point3& p) const {
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

struct materials
{
    lambertian *lambertian_mats = nullptr;
    uint32_t lambertian_count;

    metal *metal_mats = nullptr;
    uint32_t metal_count;

    dielectric *dielectric_mats = nullptr;
    uint32_t dielectric_count;

    diffuse_light *diffuse_light_mats = nullptr;
    uint32_t diffuse_light_count;

    isotropic *isotropic_mats = nullptr;
    uint32_t isotropic_count;

    materials(const std::vector<lambertian> *lambertians,
        const std::vector<metal> *metals,
        const std::vector<dielectric> *dielectrics,
        const std::vector<diffuse_light> *diffuse_lights,
        const std::vector<isotropic> *isotropics)
    {
        if (!lambertians->empty())
        {
            lambertian_count = lambertians->size();
            cudaMalloc(&lambertian_mats, lambertian_count * sizeof(lambertian));
            cudaMemcpy(lambertian_mats, lambertians->data(), lambertian_count * sizeof(lambertian), cudaMemcpyHostToDevice);
        }
        if (!metals->empty())
        {
            metal_count = metals->size();
            cudaMalloc(&metal_mats, metal_count * sizeof(metal));
            cudaMemcpy(metal_mats, metals->data(), metal_count * sizeof(metal), cudaMemcpyHostToDevice);
        }
        if (!dielectrics->empty())
        {
            dielectric_count = dielectrics->size();
            cudaMalloc(&dielectric_mats, dielectric_count * sizeof(dielectric));
            cudaMemcpy(dielectric_mats, dielectrics->data(), dielectric_count * sizeof(dielectric), cudaMemcpyHostToDevice);
        }
        if (!diffuse_lights->empty())
        {
            diffuse_light_count = diffuse_lights->size();
            cudaMalloc(&diffuse_light_mats, diffuse_light_count * sizeof(diffuse_light));
            cudaMemcpy(diffuse_light_mats, diffuse_lights->data(), diffuse_light_count * sizeof(diffuse_light), cudaMemcpyHostToDevice);
        }
        if (!isotropics->empty())
        {
            isotropic_count = isotropics->size();
            cudaMalloc(&isotropic_mats, isotropic_count * sizeof(isotropic));
            cudaMemcpy(isotropic_mats, isotropics->data(), isotropic_count * sizeof(isotropic), cudaMemcpyHostToDevice);
        }
    }
};

#endif //MATERIAL_H