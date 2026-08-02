cmake_minimum_required(VERSION 4.2)
project(ray_tracing_gpu CUDA)

set(CMAKE_CUDA_STANDARD 20)

add_executable(ray_tracing_gpu main.cu
        vec3.cuh
        util.cuh
        color.cuh
        ray.cuh
        interval.cuh
        shapes.cuh
        aabb.cuh
        material.cuh
        texture.cuh
        rtw_stb_image.cuh
        bvh.cuh
        camera.cuh
        hittable_list.cuh
        quad.cuh
        scenes.cuh)

target_compile_options(ray_tracing_gpu PRIVATE
#        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:Debug>>:-G>
    $<$<COMPILE_LANGUAGE:CUDA>:-lineinfo>
)

set_target_properties(ray_tracing_gpu PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
