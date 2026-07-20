#ifndef TEXTURE_H
#define TEXTURE_H
#include <memory>

#include "color.cuh"
#include "perlin.cuh"
#include "util.cuh"
#include "rtw_stb_image.cuh"

//TODO: Checker Texture

// class checker_texture
// {
//     public:
//
//     double inv_scale;
//     shared_ptr<texture> even;
//     shared_ptr<texture> odd;
//
//     checker_texture(double scale, shared_ptr<texture> even, shared_ptr<texture> odd)
//         : inv_scale(1.0/scale), even(even), odd(odd) {}
//
//     checker_texture(double scale, const color& c1, const color& c2)
//         : checker_texture(scale, make_shared<solid_color>(c1), make_shared<solid_color>(c2)) {}
//
//     color value(double u, double v, const point3& p) const {
//         auto xInteger = int(std::floor(inv_scale * p.x()));
//         auto yInteger = int(std::floor(inv_scale * p.y()));
//         auto zInteger = int(std::floor(inv_scale * p.z()));
//
//         bool isEven = (xInteger + yInteger + zInteger) % 2 == 0;
//
//         return isEven ? even->value(u, v, p) : odd->value(u, v, p);
//     }
// };

//TODO: Implement Image Texture

// class image_texture{
// public:
//     rtw_image image;
//     image_texture(const char* filename) : image(filename) {}
//     HD color value(real u, real v, const point3& p) const
//     {
//         if (image.height() <= 0) return color(0,1,1);
//
//         u = interval(0, 1).clamp(u);
//         v = 1.0 - interval(0, 1).clamp(v);
//
//         auto i = int(u * image.width());
//         auto j = int(v * image.height());
//         auto pixel = image.pixel_data(i, j);
//
//         real color_scale = 1.0 / 255.0;
//         return {color_scale * pixel[0], color_scale * pixel[1], color_scale * pixel[2]};
//     }
// };

//TODO: Implement Perlin Noise

// class noise_texture{
// public:
//     perlin noise;
//     double scale;
//     noise_texture(double scale) : scale(scale) {}
//
//     HD color value(double u, double v, const point3& p) const {
//         return color(0.5, 0.5, 0.5) * (1 + std::sin(scale * p.z() + 10 * noise.turb(p, 7)));
//     }
// };

#endif //TEXTURE_H
