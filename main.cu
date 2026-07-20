#include <iostream>

#include "camera.cuh"
#include "color.cuh"
#include "util.cuh"

__global__ void grad(vec3* out, int width, int height, hittable_list *world, lambertian *mat_arr, camera *cam)
{
    int x = ((blockIdx.x * blockDim.x) + threadIdx.x);
    int y = ((blockIdx.y * blockDim.y) + threadIdx.y);
    if (x >= width || y >= height)
        return;


    auto id = y * width + x;
    auto rand = xorshift32(id);

    ray r;

    r.orig = vec3::random(rand);
    r.dir = vec3::random(rand);
    point3 idk = r.at(0.5f);
    // printf("%f %f %f\n", idk.x(), idk.y(), idk.z());

    cam->image_write(x, y, out, world, mat_arr, rand);
}

int main(void)
{
    int width = 256;
    int height = 256;

    vec3 *x;

    hittable_list *world;

    lambertian *mat_arr;

    camera *cam;

    cudaDeviceSetLimit(cudaLimitStackSize, 32768);

    cudaMallocManaged(&x, width * height * sizeof(vec3));
    cudaMallocManaged(&cam, sizeof(camera));
    cudaMallocManaged(&mat_arr, sizeof(lambertian));
    cudaMallocManaged(&world, sizeof(hittable_list));

    new (mat_arr) lambertian(color(0.12,0.45,0.15));;
    new (cam) camera();
    sphere s(point3(-4, 1, 0), 1.0, 0);
    new (world) hittable_list(s);

    cam->background = {0.5, 0.7, 0.3};
    cam->samples_per_pixel = 1;
    cam->image_width = width;
    cam->image_height = height;
    cam->initialize();


    dim3 block(16, 16);
    dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);
    grad<<<grid, block>>>(x, width, height, world, mat_arr, cam);
    cudaDeviceSynchronize();

    std::cout << "P3\n" << width << ' ' << height << "\n255\n";
    for (int i = 0; i < width*height; i++) {
        std::cout << write_color(x[i]);
    }

    cudaFree(x);

    return 0;
}
