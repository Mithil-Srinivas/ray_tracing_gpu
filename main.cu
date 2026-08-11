#include <iostream>

#include "bvh.cuh"
#include "camera.cuh"
#include "color.cuh"
#include "scenes.cuh"
#include "util.cuh"

__global__ void grad(vec3* out, int width, int height, hit_method *world, materials *mat_arr, camera *cam)
{
    int x = ((blockIdx.x * blockDim.x) + threadIdx.x);
    int y = ((blockIdx.y * blockDim.y) + threadIdx.y);
    if (x >= width || y >= height)
        return;

    auto id = y * width + x;
    auto rand = xorshift32(id);

    cam->image_write(x, y, out, world, mat_arr, rand);
}

int main(void)
{
    int width = 1000;
    int height = 1000;

    rng rando(155);

    vec3 *x;

    camera *cam;

    cudaDeviceSetLimit(cudaLimitStackSize, 32768);

    cudaMallocManaged(&x, width * height * sizeof(vec3));
    cudaMallocManaged(&cam, sizeof(camera));

    static hit_method* world;
    cudaMallocManaged(&world, sizeof(hit_method));

    static materials *materials_arr;
    cudaMallocManaged(&materials_arr, sizeof(materials));

    bouncing_spheres(cam, width, height, world, materials_arr, rando);

    dim3 block(16, 16);
    dim3 grid((width + block.x - 1) / block.x, (height + block.y - 1) / block.y);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    std::cout << "Kernel Started" << std::endl;
    grad<<<grid, block>>>(x, width, height, world, materials_arr, cam);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);

    std::cout << "Elapsed time: " << ms << " ms" << std::endl;

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    cudaDeviceSynchronize();

    std::ofstream out("image.ppm");

    out << "P3\n" << width << ' ' << height << "\n255\n";
    for (int i = 0; i < width*height; i++) {
        out << write_color(x[i]);
    }

    cudaFree(x);

    return 0;
}
